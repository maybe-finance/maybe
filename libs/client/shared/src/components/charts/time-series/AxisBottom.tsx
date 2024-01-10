import type { SharedType } from '@maybe-finance/shared'
import type { SharedAxisProps } from '@visx/axis'
import type { ValidXScaleTypes } from './types'

import { AxisBottom as VisxAxisBottom } from '@visx/axis'
import { DateTime } from 'luxon'
import { useChartData } from './BaseChart'
import { useMemo } from 'react'

type Props = {
    interval?: SharedType.TimeSeriesInterval
}

/** X-axis: shows start, middle, and end dates of domain */
export function AxisBottom({
    interval = 'days',
    ...rest
}: Props & Omit<SharedAxisProps<ValidXScaleTypes>, 'scale'>) {
    const { xScale, height, margin, width } = useChartData()

    const ticks = useMemo(() => {
        const start = DateTime.fromJSDate(xScale.invert(0), { zone: 'utc' })
        const end = xScale.invert(width)
        const diff = DateTime.fromJSDate(end, { zone: 'utc' }).diff(start, 'days').days
        const middle = start.plus({ days: diff / 2 }).toJSDate()

        return [start.toJSDate(), middle, end]
    }, [width, xScale])

    return (
        <VisxAxisBottom
            scale={xScale}
            top={height - margin.bottom + 15}
            hideTicks
            hideAxisLine
            axisClassName="text-gray-100"
            numTicks={3}
            tickValues={ticks}
            tickFormat={(date) => {
                if (!date) return ''
                const zone = { zone: 'utc' }
                const fmt = interval === 'days' || interval === 'weeks' ? 'MMM d, yyyy' : 'MMM yyyy'

                return date instanceof Date
                    ? DateTime.fromJSDate(date, zone).toFormat(fmt)
                    : DateTime.fromMillis(date?.valueOf(), zone).toFormat(fmt)
            }}
            tickLabelProps={(_data, index, arr) => {
                return {
                    fill: 'currentColor',
                    textAnchor: index === arr.length - 1 ? 'end' : index === 0 ? 'start' : 'middle',
                    verticalAnchor: 'middle',
                    fontSize: 12,
                }
            }}
            {...rest}
        />
    )
}
