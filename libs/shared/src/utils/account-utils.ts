import type { SharedType } from '..'
import type { AccountCategory, AccountClassification, AccountType } from '@prisma/client'
import groupBy from 'lodash/groupBy'
import keyBy from 'lodash/keyBy'
import mapValues from 'lodash/mapValues'

export const ACCOUNT_TYPES: AccountType[] = [
    'CREDIT',
    'DEPOSITORY',
    'INVESTMENT',
    'LOAN',
    'OTHER_ASSET',
    'OTHER_LIABILITY',
    'PROPERTY',
    'VEHICLE',
]

export const CATEGORIES: Record<AccountCategory, SharedType.NormalizedCategory> = {
    cash: {
        value: 'cash',
        singular: 'Cash',
        plural: 'Cash',
    },
    credit: {
        value: 'credit',
        singular: 'Credit Card',
        plural: 'Credit Cards',
    },
    crypto: {
        value: 'crypto',
        singular: 'Crypto',
        plural: 'Crypto',
    },
    investment: {
        value: 'investment',
        singular: 'Investment',
        plural: 'Investments',
    },
    loan: {
        value: 'loan',
        singular: 'Loan',
        plural: 'Loans',
    },
    property: {
        value: 'property',
        singular: 'Real Estate',
        plural: 'Real Estate',
    },
    valuable: {
        value: 'valuable',
        singular: 'Valuable',
        plural: 'Valuables',
    },
    vehicle: {
        value: 'vehicle',
        singular: 'Vehicle',
        plural: 'Vehicles',
    },
    other: {
        value: 'other',
        singular: 'Other',
        plural: 'Other',
    },
}

export const LIABILITY_CATEGORIES = [CATEGORIES.loan, CATEGORIES.credit, CATEGORIES.other]
export const ASSET_CATEGORIES = [
    CATEGORIES.cash,
    CATEGORIES.investment,
    CATEGORIES.property,
    CATEGORIES.vehicle,
    CATEGORIES.crypto,
    CATEGORIES.valuable,
    CATEGORIES.other,
]

export const CATEGORY_MAP_SIMPLE: Record<AccountType, AccountCategory[]> = {
    INVESTMENT: ['investment', 'cash', 'other'],
    DEPOSITORY: ['cash', 'other'],
    CREDIT: ['credit'],
    LOAN: ['loan'],
    PROPERTY: ['property'],
    VEHICLE: ['vehicle'],
    OTHER_ASSET: ['cash', 'investment', 'crypto', 'valuable', 'other'],
    OTHER_LIABILITY: ['other'],
}

export const CATEGORY_MAP = mapValues(keyBy(ACCOUNT_TYPES), (accountType) =>
    CATEGORY_MAP_SIMPLE[accountType].map((category) => CATEGORIES[category])
) as Record<AccountType, SharedType.NormalizedCategory[]>

/**
 * Same logic used in the dbgenerated() classification column, used for cases
 * where the Account context is not available
 */
export function getClassification(type: AccountType): AccountClassification {
    switch (type) {
        case 'CREDIT':
        case 'LOAN':
        case 'OTHER_LIABILITY':
            return 'liability'
        default:
            return 'asset'
    }
}

export function groupAccountsByCategory<TAccount extends Pick<SharedType.Account, 'category'>>(
    accounts: TAccount[]
) {
    return Object.entries(groupBy(accounts, (a) => a.category)).map(([category, accounts]) => ({
        category: CATEGORIES[category as AccountCategory].plural,
        subtitle:
            accounts.length === 1
                ? `1 ${CATEGORIES[category as AccountCategory].singular}`
                : `${accounts.length} ${CATEGORIES[category as AccountCategory].plural}`,
        accounts,
    }))
}

/**
 * Determines a user-friendly account type name based on the account's category
 * and subcategory
 */
export function getAccountTypeName(category: string, subcategory: string): string | null {
    switch (category) {
        case 'cash':
            switch (subcategory) {
                case 'cd':
                    return 'CD account'
                case 'ebt':
                    return 'EBT account'
                case 'hsa':
                    return 'HSA'
                case 'prepaid':
                    return 'prepaid debit card'
            }

            return `${subcategory} account`

        case 'investment':
            switch (subcategory) {
                case 'hsa':
                case 'ira':
                case 'isa':
                    return subcategory.toUpperCase()
                case '401k':
                    return '401(k) account'
                case 'roth':
                    return 'Roth IRA'
                case 'roth 401k':
                    return 'Roth 401(k)'
                case 'brokerage':
                case 'pension':
                case 'retirement':
                    return `${subcategory} account`
            }

            return 'investment account'

        case 'loan':
            switch (subcategory) {
                case 'line of credit':
                    return 'line of credit'
                case 'home equity':
                    return 'home equity line of credit'
                case 'other':
                    return 'loan'
            }
            return subcategory ?? 'loan'

        case 'credit':
            return 'credit card'
    }

    return null
}

export const flattenAccounts = (
    data?: SharedType.AccountsResponse
): Array<SharedType.AccountWithConnection> => {
    if (!data) return []

    const { accounts, connections } = data

    const manual = accounts ?? []
    const connected = (connections ?? [])
        .flatMap((c) => c.accounts)
        .map((account) => {
            const cnx = connections.find((c) => c.accounts.some((a) => a.id === account.id))
            return { ...account, accountConnection: cnx }
        })

    return [...manual, ...connected]
}
