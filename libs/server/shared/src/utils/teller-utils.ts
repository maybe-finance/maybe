import { Prisma, AccountCategory, AccountType } from '@prisma/client'
import { AccountClassification } from '@prisma/client'
import type { Account } from '@prisma/client'
import type { TellerTypes } from '@maybe-finance/teller-api'
import { Duration } from 'luxon'

/**
 * Update this with the max window that Teller supports
 */
export const TELLER_WINDOW_MAX = Duration.fromObject({ years: 2 })

export function getAccountBalanceData(
    { balance, currency }: Pick<TellerTypes.AccountWithBalances, 'balance' | 'currency'>,
    classification: AccountClassification
): Pick<
    Account,
    | 'currentBalanceProvider'
    | 'currentBalanceStrategy'
    | 'availableBalanceProvider'
    | 'availableBalanceStrategy'
    | 'currencyCode'
> {
    const currentBalance = classification === AccountClassification.asset ? 'ledger' : 'available'
    return {
        currentBalanceProvider: new Prisma.Decimal(
            balance[currentBalance] ? Number(balance[currentBalance]) : 0
        ),
        currentBalanceStrategy: 'current',
        availableBalanceProvider: new Prisma.Decimal(
            balance.available ? Number(balance.available) : 0
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
