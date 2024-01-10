import type { Account } from '@prisma/client'
import type { Logger } from 'winston'
import type { IETL, SyncAccountOptions } from '@maybe-finance/server/shared'
import type { IAccountProvider } from '../../account'
import { etl } from '@maybe-finance/server/shared'

export type PropertyData = {
    pricing: {}
}

export class PropertyService implements IAccountProvider, IETL<Account, PropertyData> {
    public constructor(private readonly logger: Logger) {}

    async sync(account: Account, _options?: SyncAccountOptions) {
        await etl(this, account)
    }

    async delete(_account: Account) {
        // ToDo: implement if needed
    }

    async extract(_account: Account) {
        // ToDo: fetch pricing from Zillow|Redfin
        return {
            pricing: {},
        }
    }

    transform(_account: Account, data: PropertyData) {
        return Promise.resolve(data)
    }

    async load(_account: Account, _data: PropertyData) {
        // ToDo: save pricing valuation
        throw new Error('Method not implemented.')
    }
}
