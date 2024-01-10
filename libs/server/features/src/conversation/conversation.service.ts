import { type QueueService, ServerUtil } from '@maybe-finance/server/shared'
import type { SharedType } from '@maybe-finance/shared'
import type { Conversation, PrismaClient, Prisma, User } from '@prisma/client'
import type { Logger } from 'winston'

type SignerOpts = {
    cdnUrl: string
    pubKeyId: string
    privKey: string
}

export interface IConversationService {
    getAll(userId: User['id']): Promise<SharedType.ConversationWithMessageSummary[]>
    get(id: Conversation['id'], signerOpts?: SignerOpts): Promise<SharedType.ConversationWithDetail>
    create(data: Prisma.ConversationUncheckedCreateInput): Promise<Conversation>
    update(
        id: Conversation['id'],
        data: Prisma.ConversationUncheckedUpdateInput
    ): Promise<Conversation>
    delete(id: Conversation['id']): Promise<Conversation>
}

export class ConversationService implements IConversationService {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly queueService: QueueService
    ) {}

    async getAll(userId: User['id']) {
        const conversations = await this.prisma.conversation.findMany({
            where: { userId },
            include: {
                advisors: {
                    include: {
                        advisor: {
                            select: {
                                fullName: true,
                                title: true,
                                bio: true,
                                avatarSrc: true,
                            },
                        },
                    },
                },
                messages: { take: 1, orderBy: { createdAt: 'desc' } },
                _count: { select: { messages: true } },
            },
        })

        return conversations.map(({ messages, _count, ...conversation }) => ({
            ...conversation,
            messageCount: _count.messages,
            firstMessage: messages.at(-1) ?? null,
            lastMessage: messages[0] ?? null,
        }))
    }

    async get(id: Conversation['id'], signerConfig?: ServerUtil.SignerConfig) {
        const conversation = await this.prisma.conversation.findUniqueOrThrow({
            where: { id },
            include: {
                advisors: {
                    include: {
                        advisor: {
                            select: {
                                fullName: true,
                                title: true,
                                bio: true,
                                avatarSrc: true,
                            },
                        },
                    },
                    orderBy: {
                        createdAt: 'asc',
                    },
                },
                messages: {
                    include: {
                        user: {
                            select: {
                                advisor: {
                                    select: {
                                        fullName: true,
                                        title: true,
                                        bio: true,
                                        avatarSrc: true,
                                    },
                                },
                            },
                        },
                    },
                },
            },
        })

        return {
            ...conversation,
            messages: conversation.messages.map((msg) => ServerUtil.mapMessage(msg, signerConfig)),
        }
    }

    async create(data: Prisma.ConversationUncheckedCreateInput) {
        const conversation = await this.prisma.conversation.create({
            data,
            include: {
                user: {
                    select: {
                        ataAll: true,
                        ataSubmitted: true,
                    },
                },
            },
        })

        if (conversation.user?.ataAll || conversation.user?.ataSubmitted) {
            await this.queueService.getQueue('send-email').add('send-email', {
                type: 'conversation-notification',
                notification: {
                    type: 'submitted',
                    conversationId: conversation.id,
                },
            })
        }

        return conversation
    }

    async update(id: Conversation['id'], data: Prisma.ConversationUncheckedUpdateInput) {
        const updatedConversation = await this.prisma.conversation.update({
            where: { id },
            data,
            include: {
                user: {
                    select: {
                        ataAll: true,
                        ataClosed: true,
                    },
                },
            },
        })

        const isCloseStatus = data.status === 'closed'

        if (
            isCloseStatus &&
            (updatedConversation.user.ataAll || updatedConversation.user.ataClosed)
        ) {
            await this.queueService.getQueue('send-email').add('send-email', {
                type: 'conversation-notification',
                notification: {
                    type: 'closed',
                    conversationId: updatedConversation.id,
                },
            })
        }

        return updatedConversation
    }

    delete(id: Conversation['id']) {
        return this.prisma.conversation.delete({
            where: { id },
        })
    }
}
