import type { SyncAccountOptions } from '@maybe-finance/server/shared'
import type { Account } from '@prisma/client'

export interface IAccountProvider {
    sync(account: Account, options?: SyncAccountOptions): Promise<void>
    delete(account: Account): Promise<void>
}

export class NoOpAccountProvider implements IAccountProvider {
    sync(_account: Account) {
        return Promise.resolve()
    }

    delete(_account: Account) {
        return Promise.resolve()
    }
}

export interface IAccountProviderFactory {
    for(account: Account): IAccountProvider
}

export class AccountProviderFactory implements IAccountProviderFactory {
    constructor(
        private readonly providers: Partial<Record<Account['provider'], IAccountProvider>>
    ) {}

    for(account: Account): IAccountProvider {
        return this.providers[account.provider] ?? new NoOpAccountProvider()
    }
}
