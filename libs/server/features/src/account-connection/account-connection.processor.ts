import type { AccountConnection } from '@prisma/client'
import type { SyncConnectionQueueJobData } from '@maybe-finance/server/shared'
import type { SharedType } from '@maybe-finance/shared'
import type { Logger } from 'winston'
import type { IAccountConnectionProviderFactory } from './account-connection.provider'
import type { IAccountConnectionService } from './account-connection.service'
import { ErrorUtil, ServerUtil } from '@maybe-finance/server/shared'
import * as Sentry from '@sentry/node'
import type { ITransactionService } from '../transaction'

export interface IAccountConnectionProcessor {
    sync(
        jobData: SyncConnectionQueueJobData,
        setProgress: (progress: SharedType.AccountSyncProgress) => Promise<void>
    ): Promise<void>
}

export class AccountConnectionProcessor implements IAccountConnectionProcessor {
    constructor(
        private readonly logger: Logger,
        private readonly connectionService: IAccountConnectionService,
        private readonly transactionService: ITransactionService,
        private readonly providers: IAccountConnectionProviderFactory
    ) {}

    async sync(
        jobData: SyncConnectionQueueJobData,
        setProgress: (progress: SharedType.AccountSyncProgress) => Promise<void>
    ) {
        const connection = await this.connectionService.get(jobData.accountConnectionId)
        const provider = this.providers.for(connection)

        await ServerUtil.useSync<AccountConnection>({
            onStart: async (connection) => {
                this.logger.info(`[sync.onStart] connection=${connection.id}`, {
                    connection: connection.id,
                })
                await this.connectionService.update(connection.id, {
                    syncStatus: 'SYNCING',
                })
            },
            sync: async (connection) => {
                await Promise.all([
                    setProgress({ progress: 0.2, description: 'Syncing data' }),
                    provider.sync(connection, jobData.options),
                ])
            },
            onSyncError: async (connection, error) => {
                this.logger.error(`[sync.onSyncError] connection=${connection.id}`, {
                    connection: connection.id,
                    error: ErrorUtil.parseError(error),
                })

                const err = ErrorUtil.parseError(error)
                Sentry.captureException(err, {
                    level: 'error',
                    tags: err.sentryTags,
                    contexts: err.sentryContexts,
                })

                await Promise.all([
                    setProgress({ progress: 0.75, description: 'Syncing data' }),
                    provider.onSyncEvent(connection, { type: 'error', error }),
                ])
            },
            onSyncSuccess: async (connection) => {
                this.logger.info(`[sync.onSyncSuccess] connection=${connection.id}`, {
                    connection: connection.id,
                })

                await Promise.all([
                    setProgress({ progress: 0.4, description: 'Syncing data' }),
                    provider.onSyncEvent(connection, { type: 'success' }),
                ])

                await Promise.all([
                    setProgress({ progress: 0.6, description: 'Cleaning data' }),
                    this.transactionService.markTransfers(connection.userId),
                ])

                // Temporarily disable
                // await Promise.all([
                //     setProgress({ progress: 0.5, description: 'Syncing data' }),
                //     this.connectionService.syncSecurities(connection.id),
                // ])

                await Promise.all([
                    setProgress({ progress: 0.75, description: 'Updating balances' }),
                    this.connectionService.syncBalances(connection.id),
                ])
            },
            onEnd: async (connection) => {
                this.logger.info(`[sync.onEnd] connection=${connection.id}`, {
                    connection: connection.id,
                })

                await Promise.all([
                    setProgress({ progress: 0.9, description: 'Finishing up' }),
                    this.connectionService.update(connection.id, {
                        syncStatus: 'IDLE',
                    }),
                ])
            },
        })(connection)
    }
}
