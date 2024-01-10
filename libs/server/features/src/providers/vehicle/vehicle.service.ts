import type { Account } from '@prisma/client'
import type { Logger } from 'winston'
import type { IETL, SyncAccountOptions } from '@maybe-finance/server/shared'
import type { IAccountProvider } from '../../account'
import { etl } from '@maybe-finance/server/shared'

export type VehicleData = {
    pricing: {}
}

export class VehicleService implements IAccountProvider, IETL<Account, VehicleData> {
    public constructor(private readonly logger: Logger) {}

    async sync(account: Account, _options?: SyncAccountOptions) {
        await etl(this, account)
    }

    async delete(_account: Account) {
        // ToDo: implement if needed
    }

    /**
     * @todo fetch pricing from KBB / Edmunds
     */
    async extract(_account: Account) {
        return {
            pricing: {},
        }
    }

    transform(_account: Account, data: VehicleData) {
        return Promise.resolve(data)
    }

    async load(_account: Account, _data: VehicleData) {
        // ToDo: save pricing valuation
        throw new Error('Method not implemented.')
    }
}
