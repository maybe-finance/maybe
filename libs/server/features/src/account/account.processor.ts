import type { SyncAccountQueueJobData } from '@maybe-finance/server/shared'
import type { Account } from '@prisma/client'
import type { Logger } from 'winston'
import { ServerUtil } from '@maybe-finance/server/shared'
import type { IAccountProviderFactory } from './account.provider'
import type { IAccountService } from './account.service'

export interface IAccountProcessor {
    sync(jobData: SyncAccountQueueJobData): Promise<void>
}

export class AccountProcessor implements IAccountProcessor {
    constructor(
        private readonly logger: Logger,
        private readonly accountService: IAccountService,
        private readonly providers: IAccountProviderFactory
    ) {}

    async sync(jobData: SyncAccountQueueJobData) {
        const account = await this.accountService.get(jobData.accountId)
        const provider = this.providers.for(account)

        await ServerUtil.useSync<Account>({
            onStart: (account) => this.accountService.update(account.id, { syncStatus: 'SYNCING' }),
            sync: (account) => provider.sync(account, jobData.options),
            onSyncSuccess: (account) => this.accountService.syncBalances(account.id),
            onSyncError: async (account, error) => {
                this.logger.error(`error syncing account ${account.id}`, { error })
            },
            onEnd: (account) => this.accountService.update(account.id, { syncStatus: 'IDLE' }),
        })(account)
    }
}
