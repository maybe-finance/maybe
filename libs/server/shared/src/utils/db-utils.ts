import type { SharedType } from '@maybe-finance/shared'
import { Prisma } from '@prisma/client'
import type { Logger } from 'winston'
import { NumberUtil, SharedUtil } from '@maybe-finance/shared'

// prisma middleware that reports slow queries
export function slowQueryMiddleware(logger: Logger, cutoffDuration = 1_000): Prisma.Middleware {
    return async (params, next) => {
        const start = Date.now()
        const res = await next(params)
        const duration = Date.now() - start

        // log slow queries
        if (duration > cutoffDuration) {
            logger.warn(
                `[SLOW_QUERY] ${params.model ? `${params.model}.` : ''}${
                    params.action
                } took ${duration}ms`,
                { duration }
            )

            logger.debug(`[SLOW_QUERY] query`, params)
        }

        return res
    }
}

/**
 * converts a `TimeSeriesInterval` to a postgres interval literal
 */
export function toPgInterval(interval: SharedType.TimeSeriesInterval): string {
    switch (interval) {
        case 'days':
            return '1 day'
        case 'weeks':
            return '1 week'
        case 'months':
            return '30 days'
        case 'quarters':
            return '91 days'
        case 'years':
            return '365 days'
        default:
            throw new Error(`invalid interval: ${interval}`)
    }
}

type NumberOrDecimal = Prisma.Decimal | number

function getTrendDirection(_amount: NumberOrDecimal | null): SharedType.Trend['direction'] {
    const amount = toDecimal(_amount)
    if (!SharedUtil.nonNull(amount)) return 'flat'
    return amount.lt(-0.01) ? 'down' : amount.gt(0.01) ? 'up' : 'flat'
}

export function calculateTrend(_from: NumberOrDecimal, _to: NumberOrDecimal): SharedType.Trend {
    const from = toDecimal(_from)
    const to = toDecimal(_to)

    const amount = to.minus(from)
    const percentage = NumberUtil.calculatePercentChange(from, to)

    return {
        direction: getTrendDirection(amount),
        amount,
        percentage,
    }
}

export function toTrend(
    _amount: NumberOrDecimal | null,
    _percentage: NumberOrDecimal | null
): SharedType.Trend {
    const amount = toDecimal(_amount)
    const percentage = toDecimal(_percentage)

    return {
        direction: getTrendDirection(amount),
        amount,
        percentage,
    }
}

export function toDecimal(x: NumberOrDecimal): Prisma.Decimal
export function toDecimal(x?: NumberOrDecimal | null): Prisma.Decimal | null
export function toDecimal(x?: NumberOrDecimal | null): Prisma.Decimal | null {
    return x == null ? null : typeof x === 'number' ? new Prisma.Decimal(x).toDP(16) : x
}
