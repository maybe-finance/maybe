import type { Account, AccountCategory, AccountClassification, AccountType } from '@prisma/client'
import { Prisma } from '@prisma/client'
import { Duration } from 'luxon'
import type { FinicityTypes } from '@maybe-finance/finicity-api'

type FinicityAccount = FinicityTypes.CustomerAccount

/**
 * Finicity delivers up to 180 days prior to account addition but doesn't provide a cutoff window
 */
export const FINICITY_WINDOW_MAX = Duration.fromObject({ years: 2 })

export function getType({ type }: Pick<FinicityAccount, 'type'>): AccountType {
    switch (type) {
        case 'investment':
        case 'investmentTaxDeferred':
        case 'brokerageAccount':
        case '401k':
        case '401a':
        case '403b':
        case '457':
        case '457plan':
        case '529':
        case '529plan':
        case 'ira':
        case 'simpleIRA':
        case 'sepIRA':
        case 'roth':
        case 'roth401k':
        case 'rollover':
        case 'ugma':
        case 'utma':
        case 'keogh':
        case 'employeeStockPurchasePlan':
            return 'INVESTMENT'
        case 'creditCard':
            return 'CREDIT'
        case 'lineOfCredit':
        case 'loan':
        case 'studentLoan':
        case 'studentLoanAccount':
        case 'studentLoanGroup':
        case 'mortgage':
            return 'LOAN'
        default:
            return 'DEPOSITORY'
    }
}

export function getAccountCategory({ type }: Pick<FinicityAccount, 'type'>): AccountCategory {
    switch (type) {
        case 'checking':
        case 'savings':
        case 'cd':
        case 'moneyMarket':
            return 'cash'
        case 'investment':
        case 'investmentTaxDeferred':
        case 'brokerageAccount':
        case '401k':
        case '401a':
        case '403b':
        case '457':
        case '457plan':
        case '529':
        case '529plan':
        case 'ira':
        case 'simpleIRA':
        case 'sepIRA':
        case 'roth':
        case 'roth401k':
        case 'rollover':
        case 'ugma':
        case 'utma':
        case 'keogh':
        case 'employeeStockPurchasePlan':
            return 'investment'
        case 'mortgage':
        case 'loan':
        case 'lineOfCredit':
        case 'studentLoan':
        case 'studentLoanAccount':
        case 'studentLoanGroup':
            return 'loan'
        case 'creditCard':
            return 'credit'
        case 'cryptocurrency':
            return 'crypto'
        default:
            return 'other'
    }
}

export function getAccountBalanceData(
    { balance, currency, detail }: Pick<FinicityAccount, 'balance' | 'currency' | 'detail'>,
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
        currentBalanceProvider: new Prisma.Decimal(balance ? sign * balance : 0),
        currentBalanceStrategy: 'current',
        availableBalanceProvider: !detail
            ? null
            : detail.availableBalanceAmount != null
            ? new Prisma.Decimal(sign * detail.availableBalanceAmount)
            : detail.availableCashBalance != null
            ? new Prisma.Decimal(sign * detail.availableCashBalance)
            : null,
        availableBalanceStrategy: 'available',
        currencyCode: currency,
    }
}
