import type { Logger } from 'winston'
import type { PrismaClient } from '@prisma/client'
import type { SendEmailQueueJobData } from '@maybe-finance/server/shared'
import type { IEmailService } from './email.service'
import type { ManagementClient } from 'auth0'
import type { SharedType } from '@maybe-finance/shared'
import { ATAUtil } from '@maybe-finance/shared'
import { DateTime } from 'luxon'
import { zip } from 'lodash'

export interface IEmailProcessor {
    send(jobData: SendEmailQueueJobData): Promise<void>
    sendTrialEndReminders(): Promise<void>
    sendConversationNotification(notification: SharedType.ConversationNotification): Promise<void>
}

export class EmailProcessor implements IEmailProcessor {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly auth0: ManagementClient,
        private readonly emailService: IEmailService
    ) {}

    async send(jobData: SendEmailQueueJobData) {
        if ('type' in jobData) {
            switch (jobData.type) {
                case 'plain':
                    this.emailService.send(jobData.messages)
                    break
                case 'template':
                    this.emailService.sendTemplate(jobData.messages)
                    break
                case 'conversation-notification':
                    this.sendConversationNotification(jobData.notification)
                    break
                case 'trial-reminders':
                    this.sendTrialEndReminders()
                    break
                case 'conversation-expirations':
                    this.sendConversationExpiryNotifications()
                    break
            }
        } else {
            this.logger.warn('Failed to process email send job', jobData)
        }
    }

    async sendConversationNotification({
        type,
        conversationId,
    }: SharedType.ConversationNotification) {
        const conversation = await this.prisma.conversation.findUniqueOrThrow({
            where: { id: conversationId },
            select: {
                id: true,
                title: true,
                status: true,
                user: {
                    select: {
                        id: true,
                        auth0Id: true,
                    },
                },
            },
        })

        if (conversation.status === 'closed' && type !== 'closed') {
            this.logger.warn(`conversation is closed - skipping send of notification type=${type}`)
            return
        }

        const auth0User = await this.auth0.getUser({ id: conversation.user.auth0Id })

        if (!auth0User.email) {
            throw new Error(
                `User is missing email user=${conversation.user.id} auth0Id=${conversation.user.auth0Id}`
            )
        }

        const urls = ATAUtil.getUrls(conversation.id)

        switch (type) {
            case 'submitted': {
                await this.emailService.sendTemplate({
                    to: auth0User.email,
                    template: {
                        alias: 'ata-conversation-created',
                        model: {
                            name: auth0User.user_metadata?.firstName,
                            question: conversation.title,
                            urls,
                        },
                    },
                })
                break
            }
            default: {
                const { subject, message } = ATAUtil.getEmailNotificationContent(type)
                await this.emailService.sendTemplate({
                    to: auth0User.email,
                    template: {
                        alias: 'ata-conversation-updated',
                        model: {
                            name: auth0User.user_metadata?.firstName,
                            subject,
                            message,
                            urls,
                        },
                    },
                })
                break
            }
        }
    }

    async sendConversationExpiryNotifications() {
        const activeConversations = await this.prisma.conversation.findMany({
            where: {
                status: 'open',
            },
            include: {
                user: {
                    select: {
                        auth0Id: true,
                    },
                },
                messages: {
                    select: {
                        createdAt: true,
                    },
                },
            },
        })

        const expiringConversations = activeConversations.filter(
            (c) => ATAUtil.getExpiryStatus(c) != null
        )

        if (!expiringConversations.length) {
            this.logger.info('No expiring conversations found, skipping email notifications.')
            return
        }

        const emails = await Promise.all(
            expiringConversations.map(async (c) => {
                const auth0User = await this.auth0.getUser({ id: c.user.auth0Id })
                const emailType = ATAUtil.getExpiryStatus(c)

                return {
                    conversation: c,
                    type: emailType,
                    content: {
                        to: auth0User.email!,
                        template: {
                            alias: 'ata-conversation-updated',
                            model: {
                                name: auth0User.user_metadata!.firstName,
                                subject:
                                    emailType === 'expired'
                                        ? 'Your conversation has expired'
                                        : 'Your conversation will expire in 3 days',
                                message:
                                    emailType === 'expired'
                                        ? 'Your Ask the Advisor conversation has been open for over 2 weeks without new messages, so we have archived it due to inactivity.  To start a new conversation, please go to your dashboard and ask another question.'
                                        : 'We just wanted to reach out and let you know that your conversation with your advisor will be expiring in 3 days due to inactivity.  If you would like to keep this conversation open, please send a message from your dashboard.',
                                urls: {
                                    conversation: `https://app.maybe.co/ask-the-advisor/${c.id}`,
                                    settings: 'https://app.maybe.co/settings?tab=notifications',
                                },
                            },
                        },
                    },
                }
            })
        )

        const emailBatchResults = await this.emailService.sendTemplate(emails.map((e) => e.content))

        await Promise.all(
            zip(emailBatchResults, emails)
                .map(([result, email]) => {
                    if (result?.ErrorCode !== 0) {
                        this.logger.error(
                            `Could not send expiry email for conversation id=${email?.conversation.id}`
                        )
                        return null
                    }

                    this.logger.info(
                        `${
                            email?.type === 'expired' ? 'Closing' : 'Sending expiry email for'
                        } conversation id=${email?.conversation.id}`
                    )

                    return this.prisma.conversation.update({
                        where: { id: email?.conversation.id },
                        data: {
                            status: email?.type === 'expired' ? 'closed' : undefined,
                            expiryEmailSent:
                                email?.type === 'expiring-soon' ? new Date() : undefined,
                        },
                    })
                })
                .filter((v) => v != null)
        )
    }

    async sendTrialEndReminders() {
        // Find all users with trials expiring in under 3 days which haven't been notified in at least 7 days
        const users = await this.prisma.user.findMany({
            where: {
                trialEnd: {
                    gt: DateTime.now().toJSDate(),
                    lt: DateTime.now().plus({ days: 3 }).toJSDate(),
                },
                stripeCancelAt: null,
                OR: [
                    { trialReminderSent: null },
                    {
                        trialReminderSent: {
                            lt: DateTime.now().minus({ days: 7 }).toJSDate(),
                        },
                    },
                ],
            },
        })

        if (!users.length) return

        const results = await this.emailService.sendTemplate(
            users.map((user) => ({
                to: user.email,
                template: {
                    alias: 'trial-ending',
                    model: {
                        endDate: DateTime.fromJSDate(user.trialEnd!).toFormat('MMM dd, yyyy'),
                    },
                },
            }))
        )

        const successful = results
            .map((response, idx) => ({
                userId: users[idx]?.id,
                response,
            }))
            .filter(({ userId, response }) => {
                if (response.ErrorCode !== 0)
                    this.logger.error(`Failed to send trial end notification to user ${userId}`)

                return response.ErrorCode === 0
            })

        if (successful.length) {
            await this.prisma.user.updateMany({
                where: {
                    id: {
                        in: successful.map(({ userId }) => userId),
                    },
                },
                data: {
                    trialReminderSent: DateTime.now().toJSDate(),
                },
            })
        }
    }
}
