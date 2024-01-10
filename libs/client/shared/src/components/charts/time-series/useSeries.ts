import type { TSeriesDatumEnhanced } from './types'

import { useCallback, useMemo } from 'react'
import { useChartData } from './BaseChart'
import { tailwindScale } from './colorScales'

export function useSeries(seriesKey: string) {
    const { series: chartSeries, data, chartId, tooltipOpen, tooltipData } = useChartData()

    const seriesPrefix = useMemo(() => `${chartId}-${seriesKey}`, [chartId, seriesKey])

    const series = useMemo(() => {
        const series = chartSeries.find((s) => s.key === seriesKey)

        if (!series) throw new Error(`Invalid series key: ${seriesKey}`)

        const { accessorFn, color, isActive } = series

        return {
            data: Array.isArray(data) ? data : data[series.dataKey!],
            dataKey: series.dataKey!,
            color: color ?? tailwindScale('cyan'), // default to cyan color
            accessorFn,
            isActive: isActive ?? true, // if not specified by chart, series will show
        }
    }, [data, chartSeries, seriesKey])

    const isDefinedAccessor = useCallback(
        (datum: TSeriesDatumEnhanced): boolean => {
            return Number.isFinite(series.accessorFn(datum))
        },
        [series]
    )

    const hasUndefinedSegments = useMemo(
        () => series.data.filter(isDefinedAccessor).length !== series.data.length,
        [series.data, isDefinedAccessor]
    )

    const lineColor = useMemo(
        () =>
            typeof series.color === 'function'
                ? `url(#${seriesPrefix}-color-gradient)`
                : 'currentColor',
        [series.color, seriesPrefix]
    )

    const currentDatum = useMemo(() => {
        if (!tooltipData || !tooltipOpen) return null
        const data = tooltipData.series?.[seriesKey]
        if (!data) return null

        const value = series.accessorFn(data.originalDatum)

        if (value == null) return null

        return {
            datum: data.originalDatum,
            value,
        }
    }, [tooltipOpen, tooltipData, seriesKey, series])

    return {
        ...series,
        isDefinedAccessor,
        hasUndefinedSegments,
        lineColor,
        seriesPrefix,
        currentDatum,
    }
}
