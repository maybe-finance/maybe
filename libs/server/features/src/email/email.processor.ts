import type { Logger } from 'winston'
import type { PrismaClient } from '@prisma/client'
import type { SendEmailQueueJobData } from '@maybe-finance/server/shared'
import type { EmailService } from './email.service'
import { DateTime } from 'luxon'

export interface IEmailProcessor {
    send(jobData: SendEmailQueueJobData): Promise<void>
    sendTrialEndReminders(): Promise<void>
}

export class EmailProcessor implements IEmailProcessor {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly emailService: EmailService
    ) {}

    async send(jobData: SendEmailQueueJobData) {
        if ('type' in jobData) {
            switch (jobData.type) {
                case 'plain':
                    if (Array.isArray(jobData.messages)) {
                        this.emailService.send(jobData.messages)
                    } else {
                        this.emailService.send([jobData.messages])
                    }
                    break
                case 'template':
                    if (Array.isArray(jobData.messages)) {
                        this.emailService.sendTemplate(jobData.messages)
                    } else {
                        this.emailService.sendTemplate([jobData.messages])
                    }
                    break
                case 'trial-reminders':
                    this.sendTrialEndReminders()
                    break
            }
        } else {
            this.logger.warn('Failed to process email send job', jobData)
        }
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
