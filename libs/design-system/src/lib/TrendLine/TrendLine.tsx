import { useMemo } from 'react'
import { ParentSize } from '@visx/responsive'
import { scaleBand, scaleLinear } from '@visx/scale'
import { Group } from '@visx/group'
import { Area, Circle } from '@visx/shape'
import classNames from 'classnames'

const CIRCLE_RADIUS = 1

export interface TrendLineProps extends React.HTMLAttributes<HTMLDivElement> {
    data: {
        key: { toString(): string }
        value: number
    }[]
    /** Whether a negative trendline should be treated positively (teal vs. red) */
    inverted?: boolean
}

export default function TrendLine({
    data,
    className,
    inverted = false,
    ...rest
}: TrendLineProps): JSX.Element | null {
    const xScale = useMemo(
        () =>
            scaleBand<string>({
                domain: data.map(({ key }) => key.toString()),
                round: false,
            }),
        [data]
    )
    const yScale = useMemo(() => {
        const yDomain = data.map(({ value }) => value)

        return scaleLinear<number>({
            domain: [Math.min(...yDomain), Math.max(...yDomain)],
            round: true,
        })
    }, [data])

    const change = data[data.length - 1].value - data[0].value

    let isPositive = change > 0
    if (inverted) isPositive = !isPositive

    return data.length > 0 ? (
        <ParentSize className={classNames('relative', className)} {...rest}>
            {({ width, height }) => {
                xScale.range([0, width - CIRCLE_RADIUS * 2])
                yScale.range([height - CIRCLE_RADIUS * 2, 0])

                return (
                    <svg {...{ width, height }}>
                        <Group left={CIRCLE_RADIUS} top={CIRCLE_RADIUS}>
                            <>
                                <Area
                                    data={data}
                                    x={({ key }) => xScale(key.toString()) || 0}
                                    y={({ value }) => yScale(value)}
                                    className={
                                        change === 0
                                            ? 'text-gray-200'
                                            : isPositive
                                            ? 'text-teal'
                                            : 'text-red'
                                    }
                                    stroke="currentColor"
                                    strokeWidth={1}
                                    strokeLinejoin="round"
                                />
                                <Circle
                                    r={CIRCLE_RADIUS}
                                    cx={xScale(data[data.length - 1].key.toString())}
                                    cy={yScale(data[data.length - 1].value)}
                                    className={
                                        change === 0
                                            ? 'text-gray-200'
                                            : isPositive
                                            ? 'text-teal'
                                            : 'text-red'
                                    }
                                    fill="currentColor"
                                />
                            </>
                        </Group>
                    </svg>
                )
            }}
        </ParentSize>
    ) : null
}
