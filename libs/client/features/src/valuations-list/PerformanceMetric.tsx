import type { SharedType } from '@maybe-finance/shared'
import { TrendBadge } from '@maybe-finance/client/shared'
import { NumberUtil } from '@maybe-finance/shared'

export function PerformanceMetric({
    trend,
    isInitial = false,
    negative = false,
}: {
    trend: SharedType.Trend
    isInitial?: boolean
    negative?: boolean
}) {
    if (trend.direction === 'flat') {
        return (
            <div className="text-gray-100 text-base font-normal">
                {isInitial ? '--' : 'No change'}
            </div>
        )
    }

    return (
        <div className="flex flex-col items-end justify-end">
            <p className="text-base font-medium mb-1">
                {NumberUtil.format(trend.amount, 'currency')}
            </p>
            <TrendBadge trend={trend} negative={negative} badgeSize="sm" />
        </div>
    )
}
