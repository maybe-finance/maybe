import type { SharedType } from '@maybe-finance/shared'
import type { AccountCategory } from '@prisma/client'
import type { QueryClient } from '@tanstack/react-query'
import { DateTime } from 'luxon'
import {
    RiBankCard2Line,
    RiBankLine,
    RiBitCoinLine,
    RiCarLine,
    RiFolderLine,
    RiHandCoinLine,
    RiHomeLine,
    RiLineChartLine,
    RiVipDiamondLine,
} from 'react-icons/ri'

export function getCategoryColorClassName(category: AccountCategory) {
    return (
        (
            {
                cash: 'text-blue',
                investment: 'text-teal',
                crypto: 'text-orange',
                property: 'text-pink',
                vehicle: 'text-grape',
                valuable: 'text-green',
                loan: 'text-red',
                credit: 'text-indigo',
                other: 'text-cyan',
            } as Record<AccountCategory, any>
        )[category] ?? 'text-cyan'
    )
}

export function getCategoryIcon(category: AccountCategory) {
    return (
        (
            {
                cash: RiBankLine,
                investment: RiLineChartLine,
                crypto: RiBitCoinLine,
                property: RiHomeLine,
                vehicle: RiCarLine,
                valuable: RiVipDiamondLine,
                loan: RiHandCoinLine,
                credit: RiBankCard2Line,
                other: RiFolderLine,
            } as Record<AccountCategory, any>
        )[category] ?? RiFolderLine
    )
}

/**
 * Invalidates account queries and optionally account aggregate queries (i.e. net worth, insights)
 */
export function invalidateAccountQueries(queryClient: QueryClient, aggregates = true) {
    queryClient.invalidateQueries(['accounts'])
    queryClient.invalidateQueries(['users', 'onboarding'])

    if (aggregates) {
        queryClient.invalidateQueries(['users', 'net-worth'])
        queryClient.invalidateQueries(['users', 'insights'])
    }
}

export function formatLoanTerm({
    originationDate,
    maturityDate,
}: Pick<SharedType.Loan, 'originationDate' | 'maturityDate'>) {
    const start = DateTime.fromISO(originationDate!)
    const end = DateTime.fromISO(maturityDate!)
    const months = end.diff(start, 'months').toObject().months!

    // if the total months is within 1 month of a year, display years
    return months % 12 < 1 || months % 12 > 11
        ? `${Math.round(months / 12)} years`
        : `${Math.round(months)} months`
}
