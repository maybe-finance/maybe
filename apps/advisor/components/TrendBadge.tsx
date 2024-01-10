import { useState } from 'react'
import type { BadgeProps } from '@maybe-finance/design-system'
import { Badge } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'
import { NumberUtil } from '@maybe-finance/shared'

type TrendBadgeProps = {
    trend: SharedType.Trend
    size?: BadgeProps['size']
}

export default function TrendBadge({ trend, size = 'sm' }: TrendBadgeProps) {
    const [mode, setMode] = useState<'percent' | 'amount'>('percent')

    return (
        <Badge
            variant={
                trend.direction === 'down' ? 'red' : trend.direction === 'up' ? 'teal' : 'gray'
            }
            size={size}
            as="button"
            onClick={() => setMode((prev) => (prev === 'amount' ? 'percent' : 'amount'))}
        >
            {mode === 'percent'
                ? NumberUtil.format(trend.percentage, 'percent', {
                      maximumFractionDigits: 2,
                      signDisplay: 'exceptZero',
                  })
                : NumberUtil.format(trend.amount, 'short-currency', {
                      signDisplay: 'exceptZero',
                  })}
        </Badge>
    )
}
