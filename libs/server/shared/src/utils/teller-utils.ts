import { AccountCategory, AccountType } from '@prisma/client'
import type { TellerTypes } from '@maybe-finance/teller-api'
import { Duration } from 'luxon'

/**
 * Update this with the max window that Teller supports
 */
export const TELLER_WINDOW_MAX = Duration.fromObject({ years: 1 })

export function getType(type: TellerTypes.AccountTypes): AccountType {
    switch (type) {
        case 'depository':
            return AccountType.DEPOSITORY
        case 'credit':
            return AccountType.CREDIT
        default:
            return AccountType.OTHER_ASSET
    }
}

export function tellerTypesToCategory(tellerType: TellerTypes.AccountTypes): AccountCategory {
    switch (tellerType) {
        case 'depository':
            return AccountCategory.cash
        case 'credit':
            return AccountCategory.credit
        default:
            return AccountCategory.other
    }
}
