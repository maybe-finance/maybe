import { Badge, type BadgeVariant as BadgeVariantType } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'
import { NumberUtil } from '@maybe-finance/shared'
import cn from 'classnames'

type TrendBadgeProps = {
    trend: SharedType.Trend
    negative?: boolean
    badgeSize?: 'sm' | 'md'
    amountSize?: 'sm' | 'md'
    label?: string
    displayAmount?: boolean
}

const BadgeVariant = (
    negative: boolean
): Record<SharedType.Trend['direction'], BadgeVariantType> => ({
    down: negative ? 'teal' : 'red',
    up: negative ? 'red' : 'teal',
    flat: 'gray',
})

const AmountVariant = (negative: boolean): Record<SharedType.Trend['direction'], string> => ({
    down: negative ? 'text-teal' : 'text-red',
    up: negative ? 'text-red' : 'text-teal',
    flat: 'text-white',
})

const AmountSizeVariant = Object.freeze({
    sm: 'text-sm',
    md: 'text-base',
})

export function TrendBadge({
    trend,
    negative = false,
    label,
    badgeSize = 'md',
    amountSize,
    displayAmount = false,
}: TrendBadgeProps) {
    return (
        <div className="flex items-center space-x-2">
            <Badge variant={BadgeVariant(negative)[trend.direction]} size={badgeSize}>
                {NumberUtil.format(trend.percentage, 'percent', {
                    maximumFractionDigits: 2,
                })}
            </Badge>

            {displayAmount && (
                <span
                    className={cn(
                        AmountVariant(negative)[trend.direction],
                        AmountSizeVariant[amountSize ?? badgeSize]
                    )}
                >
                    {NumberUtil.format(trend.amount, 'currency', {
                        minimumFractionDigits: 2,
                        maximumFractionDigits: 2,
                        signDisplay: 'exceptZero',
                    })}
                </span>
            )}

            {label && <span className={AmountSizeVariant[amountSize ?? badgeSize]}>{label}</span>}
        </div>
    )
}
