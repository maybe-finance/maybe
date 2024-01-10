import { Badge } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'
import { NumberUtil } from '@maybe-finance/shared'
import { LinearGradient } from '@visx/gradient'
import { ParentSize } from '@visx/responsive'
import { scaleBand, scaleLinear } from '@visx/scale'
import { Area, AreaClosed, Circle } from '@visx/shape'
import { DateTime } from 'luxon'
import { useMemo } from 'react'

export function SecurityPriceChart({
    pricing,
}: {
    pricing: SharedType.SecurityPricing[]
}): JSX.Element {
    const xDomain = useMemo(() => pricing.map(({ date }) => date), [pricing])
    const yDomain = useMemo(() => {
        const values = pricing.map(({ priceClose }) => priceClose.toNumber())
        return [Math.min(...values), Math.max(...values)]
    }, [pricing])

    const xScale = scaleBand({
        domain: xDomain,
    })

    const yScale = scaleLinear<number>({
        domain: yDomain,
    })

    return pricing.length > 1 ? (
        <div>
            <div className="flex justify-end">
                <Badge variant="cyan" highlighted={true} size="sm">
                    {NumberUtil.format(pricing[pricing.length - 1].priceClose, 'currency')}
                </Badge>
            </div>
            <div className="w-full h-32">
                <ParentSize className="relative" debounceTime={100}>
                    {({ width, height }) => {
                        xScale.range([0, width])
                        yScale.range([height, 0])

                        return (
                            <svg width={width} height={height} className="overflow-visible">
                                {/* Cyan gradient under line */}
                                <LinearGradient
                                    id="area-gradient"
                                    className="text-cyan"
                                    fromOffset="41%"
                                    from="currentColor"
                                    fromOpacity={0.1}
                                    toOffset="97%"
                                    to="currentColor"
                                    toOpacity={0}
                                />

                                {/* Closed area beneath line with gradient */}
                                <AreaClosed
                                    yScale={yScale}
                                    data={pricing}
                                    x={({ date }) => xScale(date) || 0}
                                    y={({ priceClose }) => yScale(priceClose.toNumber())}
                                    className="text-cyan"
                                    fill="url(#area-gradient)"
                                />

                                {/* Actual line */}
                                <Area
                                    data={pricing}
                                    x={({ date }) => xScale(date) || 0}
                                    y={({ priceClose }) => yScale(priceClose.toNumber())}
                                    className="text-cyan"
                                    stroke="currentColor"
                                    strokeWidth={2}
                                />

                                {/* Circle on last data point */}
                                <Circle
                                    cx={xScale(pricing[pricing.length - 1].date)}
                                    cy={yScale(pricing[pricing.length - 1].priceClose.toNumber())}
                                    r={4}
                                    className="text-cyan"
                                    fill="currentColor"
                                />
                            </svg>
                        )
                    }}
                </ParentSize>
            </div>
            <div className="flex justify-between mt-2 text-sm text-gray-100">
                {[0, pricing.length - 1].map((idx) => (
                    <span key={idx}>
                        {DateTime.fromJSDate(pricing[idx].date).toFormat('MMM yy')}
                    </span>
                ))}
            </div>
        </div>
    ) : (
        <div className="flex items-center justify-center w-full h-32 text-gray-100">
            No historical data available
        </div>
    )
}
