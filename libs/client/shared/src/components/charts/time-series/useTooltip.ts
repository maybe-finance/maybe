import type { ChartContext, TooltipData, TooltipOptions, TSeriesDatumEnhanced } from './types'
import type { PointerEvent } from 'react'

import { localPoint } from '@visx/event'
import {
    TooltipWithBounds,
    useTooltip as useVisxTooltip,
    useTooltipInPortal,
    defaultStyles,
} from '@visx/tooltip'
import { bisector } from 'd3-array'
import { useCallback } from 'react'
import { DefaultTooltip } from './DefaultTooltip'

function getClosestDatum(data: TSeriesDatumEnhanced[], date: Date) {
    const bisect = bisector<TSeriesDatumEnhanced, Date>((d) => d.dateJS).center
    const datumIdx = bisect(data, date)

    return data[datumIdx]
}

/* Wraps Visx tooltip hook with a default handler for all series */
export function useTooltip(
    chartContext: Omit<ChartContext, 'tooltipOpen' | 'tooltipData' | 'tooltipLeft' | 'tooltipTop'>,
    options?: TooltipOptions
) {
    const { height, width, margin, series, xScale, data: chartData, y1Scale } = chartContext

    const visxTooltipInPortal = useTooltipInPortal({
        scroll: true,
        detectBounds: true,
        debounce: 200,
    })

    const visxTooltip = useVisxTooltip<TooltipData>()

    const tooltipHandler = useCallback(
        (event: PointerEvent<HTMLDivElement>) => {
            // Throw if tooltip config is invalid
            if (
                options &&
                options.referenceSeriesKey &&
                !series.find((s) => s.key === options.referenceSeriesKey)
            ) {
                throw new Error(
                    'Invalid series key specified for tooltip positioning.  Make sure series is present in Chart props.'
                )
            }

            // Bail early if not able to get mouse coordinates
            const point = localPoint(event)
            if (!point?.x || !point?.y) return
            const { x, y } = point

            const cursorDatetime = xScale.invert(x)

            // Derived x and y tooltip coordinates
            let cx: number | undefined
            let cy: number | undefined

            const datumByKey = series.reduce((prevTooltipDatum, currSeries) => {
                const data = Array.isArray(chartData) ? chartData : chartData[currSeries.dataKey!]

                const datum = getClosestDatum(data, cursorDatetime)

                if (!datum) {
                    return prevTooltipDatum
                }

                const datumYValue = currSeries.accessorFn(datum)
                const datumYCoord = datumYValue != null ? y1Scale(datumYValue) : undefined

                if (datumYCoord != null) {
                    if (
                        options?.referenceSeriesKey &&
                        currSeries.key === options.referenceSeriesKey
                    ) {
                        cy = datumYCoord
                    } else {
                        const distanceFromCursor = Math.abs(y - datumYCoord)

                        // If this is the closest coordinate so far, set it
                        if (!cy || (cy && distanceFromCursor < cy)) {
                            cy = datumYCoord
                        }
                    }
                }

                const datumXCoord = xScale(datum.dateJS)
                if (!cx || (cx && datumXCoord < cx)) {
                    cx = datumXCoord
                }

                return {
                    date: datum.date,
                    dateJS: datum.dateJS,
                    series: {
                        ...prevTooltipDatum.series,
                        [currSeries.key]: {
                            originalSeries: currSeries,
                            originalDatum: datum,
                            // Always return null values for inactive series
                            value: currSeries.isActive ? datumYValue ?? null : null,
                        },
                    },
                    values: [
                        ...(prevTooltipDatum.values ?? []),

                        // Always return null values for inactive series
                        currSeries.isActive ? datumYValue ?? null : null,
                    ],
                }
            }, {} as TooltipData)

            // Tells us whether mouse is within chart and NOT hovering an axis
            const isHoveringInnerChart =
                y < height - margin.bottom &&
                y > margin.top &&
                x > margin.left &&
                x < width - margin.right

            if (isHoveringInnerChart && cx && cy) {
                visxTooltip.showTooltip({
                    tooltipLeft: cx,
                    tooltipTop: cy,
                    tooltipData: datumByKey,
                })
            } else {
                visxTooltip.hideTooltip()
            }
        },
        [visxTooltip, height, width, margin, chartData, options, series, xScale, y1Scale]
    )

    const TooltipWrapper = options?.renderInPortal
        ? visxTooltipInPortal.TooltipInPortal
        : TooltipWithBounds

    return {
        tooltipHandler,
        TooltipWrapper,
        DefaultTooltip,
        tooltipPortalRef: visxTooltipInPortal.containerRef,
        defaultStyles,
        ...visxTooltip,
    }
}
