import type { SyncConnectionOptions } from '@maybe-finance/server/shared'
import type { AccountConnection } from '@prisma/client'

export type AccountConnectionSyncEvent = { type: 'error'; error: unknown } | { type: 'success' }

export interface IAccountConnectionProvider {
    sync(connection: AccountConnection, options?: SyncConnectionOptions): Promise<void>
    onSyncEvent(connection: AccountConnection, event: AccountConnectionSyncEvent): Promise<void>
    delete(connection: AccountConnection): Promise<void>
}

export interface IAccountConnectionProviderFactory {
    for(connection: AccountConnection): IAccountConnectionProvider
}

export class AccountConnectionProviderFactory implements IAccountConnectionProviderFactory {
    constructor(
        private readonly providers: Record<AccountConnection['type'], IAccountConnectionProvider>
    ) {}

    for(connection: AccountConnection): IAccountConnectionProvider {
        const provider = this.providers[connection.type]
        if (!provider) throw new Error(`Unsupported connection type: ${connection.type}`)
        return provider
    }
}
