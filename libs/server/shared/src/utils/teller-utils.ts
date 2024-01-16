import {
    Prisma,
    AccountCategory,
    AccountType,
    type AccountClassification,
    type Account,
} from '@prisma/client'
import type { TellerTypes } from '@maybe-finance/teller-api'
import { Duration } from 'luxon'

/**
 * Update this with the max window that Teller supports
 */
export const TELLER_WINDOW_MAX = Duration.fromObject({ years: 1 })

export function getAccountBalanceData(
    { balances, currency }: Pick<TellerTypes.AccountWithBalances, 'balances' | 'currency'>,
    classification: AccountClassification
): Pick<
    Account,
    | 'currentBalanceProvider'
    | 'currentBalanceStrategy'
    | 'availableBalanceProvider'
    | 'availableBalanceStrategy'
    | 'currencyCode'
> {
    // Flip balance values to positive for liabilities
    const sign = classification === 'liability' ? -1 : 1

    return {
        currentBalanceProvider: new Prisma.Decimal(
            balances.ledger ? sign * Number(balances.ledger) : 0
        ),
        currentBalanceStrategy: 'current',
        availableBalanceProvider: new Prisma.Decimal(
            balances.available ? sign * Number(balances.available) : 0
        ),
        availableBalanceStrategy: 'available',
        currencyCode: currency,
    }
}

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
