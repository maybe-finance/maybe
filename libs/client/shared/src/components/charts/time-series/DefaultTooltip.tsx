import type { SeriesDatum, TooltipOptions } from './types'

import { NumberUtil } from '@maybe-finance/shared'
import { DateTime } from 'luxon'
import { useMemo } from 'react'
import { useChartData } from './BaseChart'
import { tailwindScale } from './colorScales'
import classNames from 'classnames'

type Props = {
    title: TooltipOptions['tooltipTitle']
}

/**
 * Default tooltip will loop through all of the active series and print the value of the datum
 *
 * This is rendered outside SVG, so wrap in normal div container
 */
export function DefaultTooltip({ title: _title }: Props) {
    const { series, data, tooltipData } = useChartData()

    const title = useMemo(() => {
        if (!tooltipData) return ''
        if (_title) return _title(tooltipData)

        return DateTime.fromISO(tooltipData.date, { zone: 'utc' }).toFormat('MMM dd, yyyy')
    }, [_title, tooltipData])

    const seriesWithVariance = useMemo(() => {
        if (!tooltipData) return []

        return series
            .filter((s) => s.isActive) // by default, don't show non-active series in the tooltip
            .map(
                ({
                    key: seriesKey,
                    accessorFn,
                    showVariance,
                    color,
                    dataKey,
                    negative,
                    ...rest
                }) => {
                    const seriesData = Array.isArray(data) ? data : data[dataKey!]
                    let trend: SeriesDatum['trend']

                    const curr = tooltipData.series?.[seriesKey].value

                    // If enabled, calculate the trend and populate
                    if (showVariance && curr && tooltipData) {
                        const nonNullValues = seriesData.filter((v) => accessorFn(v) !== undefined)

                        const first = accessorFn(nonNullValues[0])

                        if (first) {
                            const diff = curr - first
                            const percentage = NumberUtil.calculatePercentChange(first, curr)

                            const up = negative ? 'down' : 'up'
                            const down = negative ? 'up' : 'down'

                            trend = {
                                amount: diff,
                                percentage,
                                direction:
                                    percentage > 0.01 ? up : percentage < -0.01 ? down : 'flat',
                            }
                        }
                    }

                    return {
                        accessorFn,
                        value: curr,
                        trend,
                        color:
                            (color && typeof color === 'function'
                                ? tooltipData.series?.[seriesKey]
                                    ? color(tooltipData.series[seriesKey].originalDatum)
                                    : tailwindScale('cyan')
                                : color) ?? tailwindScale('cyan'),
                        ...rest,
                    }
                }
            )
    }, [series, tooltipData, data])

    if (!title) return null

    return (
        <div className="flex flex-col gap-1 bg-gray-700 rounded border border-gray-600 text-base text-gray-50 p-2 min-w-[225px]">
            <span>{title}</span>

            {seriesWithVariance
                .filter((s) => s.isActive)
                .map((s, idx) => (
                    <div key={idx} className="flex items-center gap-2 text-white">
                        <span
                            className={classNames(
                                'inline-block w-1 rounded-lg leading-none bg-current'
                            )}
                            style={{ color: s.color }}
                            role="presentation"
                        >
                            &nbsp;
                        </span>
                        {s.label && <span>{s.label}</span>}
                        <span className={classNames('font-medium', s.label && 'ml-auto')}>
                            {NumberUtil.format(s.value, s.format ?? 'currency')}
                        </span>
                        {s.trend && (
                            <div
                                className={classNames(
                                    'flex items-center gap-1 font-medium',
                                    s.trend.direction === 'up'
                                        ? 'text-teal'
                                        : s.trend.direction === 'down'
                                        ? 'text-red'
                                        : 'text-gray-50',
                                    !s.label && 'ml-auto'
                                )}
                            >
                                <span className="ml-auto">
                                    {s.trend.amount && (
                                        <span>
                                            {NumberUtil.format(
                                                s.trend.amount,
                                                s?.format ?? 'currency',
                                                {
                                                    signDisplay: 'exceptZero',
                                                }
                                            )}
                                        </span>
                                    )}
                                </span>
                                <span>({NumberUtil.format(s.trend.percentage, 'percent')})</span>
                            </div>
                        )}
                    </div>
                ))}
        </div>
    )
}
