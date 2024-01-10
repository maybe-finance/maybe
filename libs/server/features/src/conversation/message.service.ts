import type { QueueService } from '@maybe-finance/server/shared'
import type { Prisma, Message, PrismaClient } from '@prisma/client'
import type { Logger } from 'winston'

export interface IMessageService {
    get(id: Message['id']): Promise<Message>
    create(data: Prisma.MessageUncheckedCreateInput, isAdvisorMessage: boolean): Promise<Message>
    update(id: Message['id'], data: Prisma.MessageUncheckedUpdateInput): Promise<Message>
    delete(id: Message['id']): Promise<Message>
}

export class MessageService implements IMessageService {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly queueService: QueueService
    ) {}

    get(id: Message['id']): Promise<Message> {
        return this.prisma.message.findUniqueOrThrow({
            where: { id },
        })
    }

    async create(
        data: Prisma.MessageUncheckedCreateInput,
        isAdvisorMessage: boolean
    ): Promise<Message> {
        const newMessage = await this.prisma.message.create({
            data,
            include: {
                conversation: {
                    include: {
                        user: {
                            select: {
                                id: true,
                                ataAll: true,
                                ataUpdate: true,
                            },
                        },
                    },
                },
                user: {
                    select: {
                        id: true,
                        ataAll: true,
                        ataUpdate: true,
                    },
                },
            },
        })

        if (isAdvisorMessage && (newMessage.user?.ataAll || newMessage.user?.ataUpdate)) {
            // Notify user that the advisor has seen their message
            await this.queueService.getQueue('send-email').add('send-email', {
                type: 'conversation-notification',
                notification: {
                    type: 'update',
                    conversationId: newMessage.conversationId,
                },
            })
        }

        return newMessage
    }

    update(id: Message['id'], data: Prisma.MessageUncheckedUpdateInput): Promise<Message> {
        return this.prisma.message.update({
            where: { id },
            data,
        })
    }

    delete(id: Message['id']): Promise<Message> {
        return this.prisma.message.delete({
            where: { id },
        })
    }
}
