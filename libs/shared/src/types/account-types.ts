import type {
    Account,
    AccountType,
    AccountClassification,
    AccountConnection,
    AccountConnectionType,
    AccountConnectionStatus,
    Holding,
    InvestmentTransaction,
    Security,
    Transaction,
    Valuation,
    Prisma,
    AccountCategory,
    TransactionType,
} from '@prisma/client'
import type { TimeSeries, TimeSeriesResponseWithDetail, Trend } from './general-types'
import type { TransactionEnriched } from './transaction-types'

/**
 * ================================================================
 * ======               Account Detail                       ======
 * ================================================================
 */
export type {
    Account,
    AccountType,
    AccountClassification,
    AccountConnection,
    AccountConnectionType,
    AccountConnectionStatus,
    Valuation,
}

export type Loan = {
    originationDate?: string
    maturityDate?: string
    originationPrincipal?: number
    interestRate: { type: 'fixed'; rate?: number } | { type: 'arm' } | { type: 'variable' }
    loanDetail: { type: 'student' } | { type: 'mortgage' } | { type: 'other' }
}

export type Credit = {
    isOverdue?: boolean
    lastPaymentAmount?: number
    lastPaymentDate?: string
    lastStatementAmount?: number
    lastStatementDate?: string
    minimumPayment?: number
}

export type AccountSyncProgress = {
    description: string
    progress?: number // 0-1
}

export type AccountDetail = Omit<Account, 'loan' | 'credit'> & {
    accountConnection: AccountConnection
    transactions: Transaction[]
    investmentTransactions: InvestmentTransaction[]
    valuations: Array<Valuation & { security: Security }>
    holdings: Holding[]
    loan: Loan | null
    credit: Credit | null
}

export type AccountWithConnection = Account & { accountConnection?: AccountConnection }

export type AccountsResponse = {
    accounts: Account[]
    connections: (ConnectionWithAccounts & ConnectionWithSyncProgress)[]
}

export enum PageSize {
    Transaction = 50,
    InvestmentTransaction = 25,
    Valuation = 50,
    Holding = 50,
    Institution = 50,
}

export type NormalizedCategory = {
    value: AccountCategory
    singular: string
    plural: string
}

/**
 * ================================================================
 * ======                  Connections                       ======
 * ================================================================
 */

export type ConnectionWithAccounts = AccountConnection & {
    accounts: Account[]
}

export type ConnectionWithSyncProgress = AccountConnection & {
    syncProgress?: AccountSyncProgress
}

/**
 * ================================================================
 * ======               Account Timeseries                   ======
 * ================================================================
 */

export type AccountBalanceTimeSeriesData = {
    date: string // yyyy-mm-dd
    balance: Prisma.Decimal
}

export type AccountBalanceResponse = TimeSeriesResponseWithDetail<
    TimeSeries<AccountBalanceTimeSeriesData>
>

export type AccountReturnTimeSeriesData = {
    date: string
    account: {
        rateOfReturn: Prisma.Decimal
        contributions?: Prisma.Decimal
        contributionsPeriod?: Prisma.Decimal
    }
    comparisons?: {
        [ticker in string]?: Prisma.Decimal
    }
}

export type AccountReturnResponse = TimeSeries<AccountReturnTimeSeriesData>

export type AccountTransactionResponse = {
    transactions: TransactionEnriched[]
    totalTransactions: number
}

export type AccountHolding = Pick<
    Holding,
    | 'id'
    | 'securityId'
    | 'costBasis'
    | 'costBasisUser'
    | 'costBasisProvider'
    | 'quantity'
    | 'value'
    | 'excluded'
> &
    Pick<Security, 'symbol' | 'name' | 'sharesPerContract'> & {
        price: Prisma.Decimal
        trend: {
            total: Trend | null
            today: Trend | null
        }
    }

export type AccountHoldingResponse = {
    holdings: AccountHolding[]
    totalHoldings: number
}

export type AccountInvestmentTransaction = InvestmentTransaction & { security?: Security }

export type AccountInvestmentTransactionResponse = {
    investmentTransactions: AccountInvestmentTransaction[]
    totalInvestmentTransactions: number
}

export type AccountRollupTimeSeries = TimeSeries<
    Pick<AccountBalanceTimeSeriesData, 'date' | 'balance'> & {
        rollupPct: Prisma.Decimal
        totalPct: Prisma.Decimal
    }
>

type AccountRollupGroup<TKey, TItem> = {
    key: TKey
    title: string
    balances: AccountRollupTimeSeries
    items: TItem[]
}

export type AccountRollup = AccountRollupGroup<
    AccountClassification,
    AccountRollupGroup<
        AccountCategory,
        Pick<Account, 'id' | 'name' | 'mask'> & {
            connection: Pick<AccountConnection, 'name'> | null
            syncing: boolean
            balances: AccountRollupTimeSeries
        }
    >
>[]

export type AccountValuationsResponse = {
    valuations: (Valuation & {
        trend: {
            period: Trend
            total: Trend
        } | null
    })[]
    trends: {
        date: string
        amount: Prisma.Decimal
        period: Trend
        total: Trend
    }[]
}

export type AccountInsights = {
    portfolio?: {
        return: {
            '1m': Trend | null
            '1y': Trend | null
            ytd: Trend | null
        }
        pnl: Trend | null
        costBasis: Prisma.Decimal | null
        contributions: {
            ytd: {
                amount: Prisma.Decimal | null
                monthlyAvg: Prisma.Decimal | null
            }
            lastYear: {
                amount: Prisma.Decimal | null
                monthlyAvg: Prisma.Decimal | null
            }
        }
        fees: Prisma.Decimal
        holdingBreakdown: {
            asset_class: string // 'stocks' | 'fixed_income' | 'cash' | 'crypto' | 'other'
            amount: Prisma.Decimal
            percentage: Prisma.Decimal
        }[]
    }
}
