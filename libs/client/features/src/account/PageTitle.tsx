import type { SharedType } from '@maybe-finance/shared'
import { SmallDecimals, TrendBadge } from '@maybe-finance/client/shared'
import { LoadingPlaceholder } from '@maybe-finance/design-system'

type Props = {
    isLoading: boolean
    title?: string
    value?: string
    trend?: SharedType.Trend
    trendLabel?: string
    trendNegative?: boolean
}

export function PageTitle({ isLoading, title, value, trend, trendLabel, trendNegative }: Props) {
    return (
        <div className="space-y-2 min-h-[120px]">
            <LoadingPlaceholder
                isLoading={isLoading}
                maxContent
                placeholderContent={<h3>Placeholder Title</h3>}
            >
                {title && <h3>{title}</h3>}
            </LoadingPlaceholder>

            <LoadingPlaceholder
                isLoading={isLoading}
                maxContent
                placeholderContent={
                    <h2>
                        <SmallDecimals value={'$2,000.20'} />
                    </h2>
                }
            >
                <h2 data-testid="current-data-value">
                    <SmallDecimals value={value} />
                </h2>
            </LoadingPlaceholder>

            <LoadingPlaceholder
                isLoading={isLoading}
                maxContent
                placeholderContent={<div className="h-8 w-[150px]" />}
            >
                <span className="text-sm text-gray-50">
                    {trend && (
                        <TrendBadge
                            trend={trend}
                            label={trendLabel}
                            negative={trendNegative}
                            displayAmount
                        />
                    )}
                </span>
            </LoadingPlaceholder>
        </div>
    )
}
