import type { PrismaClient, User } from '@prisma/client'
import type { Job } from 'bull'
import type { Logger } from 'winston'
import type { BullQueue, IBullQueueEventHandler } from '@maybe-finance/server/shared'
import * as Sentry from '@sentry/node'
import { ErrorUtil } from '@maybe-finance/server/shared'

const printJob = (job: Job) =>
    `Job{queue=${job.queue.name} id=${job.id} name=${job.name} ts=${
        job.timestamp
    } data=${JSON.stringify(job.data)}}`

export class BullQueueEventHandler implements IBullQueueEventHandler {
    constructor(private readonly logger: Logger, private readonly prisma: PrismaClient) {}

    onQueueCreated({ queue }: BullQueue) {
        // https://github.com/OptimalBits/bull/blob/develop/REFERENCE.md#events
        queue.on('active', (job, _jobPromise) => {
            this.logger.info(`[job.active] ${printJob(job)}`)
        })

        queue.on('completed', (job, _result) => {
            this.logger.info(`[job.completed] ${printJob(job)}`)
        })

        queue.on('stalled', async (job) => {
            this.logger.warn(`[job.stalled] ${printJob(job)}`)
        })

        queue.on('lock-extension-failed', (job, err) => {
            this.logger.warn(`[job.lock-extension-failed] ${printJob(job)}`, { err })
        })

        queue.on('progress', (job, progress) => {
            this.logger.info(`[job.progress] ${printJob(job)}`, { progress })
        })

        queue.on('failed', async (job, error) => {
            this.logger.error(`[job.failed] ${printJob(job)}`, { error })

            const user = await this.getUserFromJob(job)

            Sentry.withScope((scope) => {
                scope.setUser(user ? {} : null)

                scope.setTags({
                    'queue.name': job.queue.name,
                    'job.name': job.name,
                })

                scope.setContext('Job Info', {
                    queue: job.queue.name,
                    job: job.name,
                    attempts: job.attemptsMade,
                    data: job.data,
                })

                const err = ErrorUtil.parseError(error)

                Sentry.captureException(error, {
                    level: 'error',
                    tags: err.sentryTags,
                    contexts: err.sentryContexts,
                })
            })
        })

        queue.on('error', async (error) => {
            this.logger.error(`[queue.error]`, { error })

            const err = ErrorUtil.parseError(error)

            Sentry.captureException(error, {
                level: 'error',
                tags: err.sentryTags,
                contexts: {
                    ...err.sentryContexts,
                    queue: { name: queue.name },
                },
            })
        })
    }

    private async getUserFromJob(job: Job) {
        let user: Pick<User, 'id' | 'auth0Id'> | undefined

        try {
            if (job.queue.name === 'sync-account' && 'accountId' in job.data) {
                const account = await this.prisma.account.findUniqueOrThrow({
                    where: { id: job.data.accountId },
                    include: {
                        accountConnection: { include: { user: true } },
                        user: true,
                    },
                })

                user = account.user ?? account.accountConnection?.user
            }

            if (job.queue.name === 'sync-account-connection' && 'accountConnectionId' in job.data) {
                const accountConnection = await this.prisma.accountConnection.findUniqueOrThrow({
                    where: { id: job.data.accountConnectionId },
                    include: {
                        user: true,
                    },
                })

                user = accountConnection.user
            }

            return user
        } catch (err) {
            // Gracefully return if no user identified successfully
            return null
        }
    }
}
