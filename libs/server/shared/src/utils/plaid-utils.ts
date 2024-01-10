import type { Account, AccountType } from '@prisma/client'
import { Prisma, AccountCategory } from '@prisma/client'
import type {
    Transaction as PlaidTransaction,
    AccountBalance as PlaidAccountBalance,
    Holding,
    MortgageLiability,
    StudentLoan,
    CreditCardLiability,
} from 'plaid'
import { AccountType as PlaidAccountType, AccountSubtype as PlaidAccountSubtype } from 'plaid'
import { Duration } from 'luxon'
import { countBy } from 'lodash'
import type { SharedType } from '@maybe-finance/shared'

// From the "taxonomy csv file" on the transactions docs page - https://plaid.com/docs/api/products/transactions/#transactionsget
type PersonalFinanceCategoryPrimary =
    | 'INCOME'
    | 'TRANSFER_IN'
    | 'TRANSFER_OUT'
    | 'LOAN_PAYMENTS'
    | 'BANK_FEES'
    | 'ENTERTAINMENT'
    | 'FOOD_AND_DRINK'
    | 'GENERAL_MERCHANDISE'
    | 'HOME_IMPROVEMENT'
    | 'MEDICAL'
    | 'PERSONAL_CARE'
    | 'GENERAL_SERVICES'
    | 'GOVERNMENT_AND_NON_PROFIT'
    | 'TRANSPORTATION'
    | 'TRAVEL'
    | 'RENT_AND_UTILITIES'

/**
 * Plaid only delivers 2 years worth of data at maximum
 */
export const PLAID_WINDOW_MAX = Duration.fromObject({ years: 2 })

export function getAccountBalanceData(
    {
        current,
        available,
        iso_currency_code,
        unofficial_currency_code,
    }: Pick<
        PlaidAccountBalance,
        'current' | 'available' | 'iso_currency_code' | 'unofficial_currency_code'
    >,
    plaidType?: PlaidAccountType
): Pick<
    Account,
    | 'currentBalanceProvider'
    | 'currentBalanceStrategy'
    | 'availableBalanceProvider'
    | 'availableBalanceStrategy'
    | 'currencyCode'
> {
    const currencyCode = iso_currency_code || unofficial_currency_code || 'USD'

    return {
        currentBalanceProvider: current != null ? new Prisma.Decimal(current) : null,
        currentBalanceStrategy:
            // For investment accounts with different current/available balances,
            // We assume that one is a portfolio value and the other is a cash value and combine them
            plaidType === PlaidAccountType.Investment &&
            current != null &&
            available != null &&
            current !== available
                ? 'sum'
                : 'current',
        availableBalanceProvider: available != null ? new Prisma.Decimal(available) : null,
        availableBalanceStrategy: 'available',
        currencyCode,
    }
}

export function getType(plaidType: PlaidAccountType): AccountType {
    switch (plaidType) {
        case PlaidAccountType.Depository:
            return 'DEPOSITORY'
        case PlaidAccountType.Investment:
        case PlaidAccountType.Brokerage:
            return 'INVESTMENT'
        case PlaidAccountType.Credit:
            return 'CREDIT'
        case PlaidAccountType.Loan:
            return 'LOAN'
        default:
            return 'OTHER_ASSET'
    }
}

export function isPlaidLiability(plaidType: string | null, plaidSubtype: string | null) {
    const { Loan, Credit } = PlaidAccountType
    const { Student, Mortgage, CreditCard, Paypal } = PlaidAccountSubtype

    if (plaidType === Loan && (plaidSubtype === Student || plaidSubtype === Mortgage)) {
        return true
    }

    if (plaidType === Credit && (plaidSubtype === CreditCard || plaidSubtype === Paypal)) {
        return true
    }

    return false
}

export function plaidTypesToCategory(plaidType: PlaidAccountType): AccountCategory {
    switch (plaidType) {
        case PlaidAccountType.Depository:
            return AccountCategory.cash
        case PlaidAccountType.Investment:
        case PlaidAccountType.Brokerage:
            return AccountCategory.investment
        case PlaidAccountType.Loan:
            return AccountCategory.loan
        case PlaidAccountType.Credit:
            return AccountCategory.credit
        default:
            return AccountCategory.other
    }
}

export function getHoldingsWithDerivedIds<
    THolding extends Pick<Holding, 'account_id' | 'security_id'>
>(holdings: THolding[]) {
    const counts = countBy(holdings, getPlaidHoldingId)

    return holdings.map((h, idx) => {
        const id = getPlaidHoldingId(h)
        const derivedId = counts[id] > 1 ? `${id}.index[${idx}]` : id

        return {
            ...h,
            derivedId,
        }
    })
}

export function getPlaidHoldingId(holding: Pick<Holding, 'account_id' | 'security_id'>) {
    return `account[${holding.account_id}].security[${holding.security_id}]`
}

export function normalizeMortgageData(mortgage: MortgageLiability): SharedType.Loan {
    return {
        originationDate: mortgage.origination_date ?? undefined,
        originationPrincipal: mortgage.origination_principal_amount ?? undefined,
        maturityDate: mortgage.maturity_date ?? undefined,
        interestRate:
            mortgage.interest_rate.type === 'fixed'
                ? { type: 'fixed', rate: mortgage.interest_rate.percentage ?? undefined }
                : { type: 'variable' },
        loanDetail: { type: 'mortgage' },
    }
}

export function normalizeStudentLoanData(studentLoan: StudentLoan): SharedType.Loan {
    return {
        originationDate: studentLoan.origination_date ?? undefined,
        originationPrincipal: studentLoan.origination_principal_amount ?? undefined,
        maturityDate: studentLoan.expected_payoff_date ?? undefined,
        interestRate: {
            type: 'fixed', // assume all Plaid student loans are fixed rate (user can always override later)
            rate: studentLoan.interest_rate_percentage ?? undefined,
        },
        loanDetail: { type: 'student' },
    }
}

export function normalizeCreditData(credit: CreditCardLiability): SharedType.Credit {
    return {
        isOverdue: credit.is_overdue ?? undefined,
        lastPaymentAmount: credit.last_payment_amount ?? undefined,
        lastPaymentDate: credit.last_payment_date ?? undefined,
        lastStatementAmount: credit.last_statement_balance ?? undefined,
        lastStatementDate: credit.last_statement_issue_date ?? undefined,
        minimumPayment: credit.minimum_payment_amount ?? undefined,
    }
}
