import type { Prisma } from '@prisma/client'
import { DateTime } from 'luxon'

/**
 * For simplicity, integration tests should generally stay within the following date range:
 *
 *    2021-12-01 => 2022-01-02
 *
 * By choosing these dates, we're covering a couple important edge cases:
 *
 * - Can test data when year changes
 * - Can test data when month changes
 * - Gives us 1 full month (Dec)
 * - Dates are guaranteed to be in the past with REAL data (helpful for stock prices)
 * - Range is small enough for testing
 */

const now = DateTime.fromISO('2022-01-03', { zone: 'utc' })

const lowerBound = DateTime.fromISO('2021-12-01', { zone: 'utc' })

export const testDates = {
    now,
    lowerBound,
    totalDays: now.diff(lowerBound, 'days').days,
    prismaWhereFilter: {
        date: {
            gte: lowerBound.toJSDate(),
            lte: now.toJSDate(),
        },
    } as Prisma.AccountBalanceWhereInput,
}
