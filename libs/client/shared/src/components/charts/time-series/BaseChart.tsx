import type { ChartContext, ChartData, ChartDataContext, ChartProps, Datum, Spacing } from './types'

import type { SharedType } from '@maybe-finance/shared'
import { DateUtil } from '@maybe-finance/shared'
import { GridRows } from '@visx/grid'
import { scaleLinear, scaleUtc } from '@visx/scale'
import { Line } from '@visx/shape'
import mapValues from 'lodash/mapValues'
import { createContext, useContext, useMemo } from 'react'
import { AxisBottom } from './AxisBottom'
import { AxisLeft } from './AxisLeft'
import { useTooltip } from './useTooltip'

const Context = createContext<ChartDataContext | undefined>(undefined)

export const useChartData = () => {
    const ctx = useContext(Context)

    if (!ctx) throw new Error('Must place useChartData() inside <Chart /> component')

    return ctx
}

export function BaseChart<TDatum extends Datum>({
    children,
    id: chartId,
    width,
    height,
    dateRange,
    series,
    data,
    interval = 'days',
    xAxis,
    y1Axis,
    xScale: _xScale,
    y1Scale: _y1Scale,
    margin,
    padding,
    tooltipOptions,
    renderTooltip,
}: Omit<ChartProps<TDatum>, 'data' | 'margin' | 'dateRange' | 'renderOverlay'> & {
    data: ChartData<TDatum>
    margin: Spacing
    dateRange: SharedType.DateRange<string>
} & { width: number; height: number }) {
    if (!Array.isArray(data) && series.some((s) => s.dataKey === undefined)) {
        throw new Error(
            'When data is provided in key:value format, `dataKey` must be provided for each series'
        )
    }

    const enhancedSeries = useMemo(() => {
        return series.map((s) => ({
            ...s,
            isActive: s.isActive ?? true,
            showVariance:
                s.showVariance ?? series.filter((s) => s.isActive ?? true).length > 1
                    ? false
                    : true,
        }))
    }, [series])

    const enhancedData = useMemo(() => {
        if (Array.isArray(data)) {
            return data.map((d) => ({ ...d, dateJS: DateUtil.strToDate(d.date) }))
        }

        return mapValues(data, (arr) =>
            arr?.map((d) => ({
                ...d,
                dateJS: DateUtil.strToDate(d.date), // added for convenience
            }))
        )
    }, [data])

    // Find min and max y values for all series
    const { minY, maxY } = useMemo(() => {
        const values = enhancedSeries
            .filter((s) => s.isActive)
            .map((s) => {
                return Array.isArray(data)
                    ? data.map((d) => s.accessorFn(d))
                    : data[s.dataKey!].map((d) => s.accessorFn(d))
            })
            .flat()
            .filter((v): v is number => v != null)

        const minY = Math.min(...values)
        const maxY = Math.max(...values)

        // Adds % padding if specified (i.e. if max = 100 and padding is 10%, max value is 100 + (100 * 0.10) = 110 units)
        return {
            minY: minY - Math.abs(minY) * (padding?.bottom ?? 0),
            maxY: maxY + Math.abs(maxY) * (padding?.top ?? 0),
        }
    }, [data, enhancedSeries, padding?.bottom, padding?.top])

    // Default configurations for scales
    const { y1Scale, xScale } = useMemo(() => {
        // https://observablehq.com/@d3/margin-convention
        const xRange = [margin.left, width - margin.right]
        const yRange = [height - margin.bottom, margin.top]

        return {
            y1Scale:
                _y1Scale ??
                scaleLinear<number>({
                    domain: [minY, maxY],
                    range: yRange,
                    nice: true,
                    clamp: true,
                }),
            xScale:
                _xScale ??
                scaleUtc<number>({
                    domain: [
                        DateUtil.strToDate(dateRange.start),
                        DateUtil.strToDate(dateRange.end),
                    ],
                    range: xRange,
                    nice: {
                        interval: DateUtil.toD3Interval(interval),
                        step: interval === 'quarters' ? 3 : 1,
                    },
                    clamp: true,
                }),
        }
    }, [
        _xScale,
        _y1Scale,
        dateRange.start,
        dateRange.end,
        interval,
        minY,
        maxY,
        height,
        width,
        margin,
    ])

    const chartCtx: ChartContext = {
        chartId,
        xScale,
        y1Scale,
        margin,
        width,
        height,
        data: enhancedData,
        series: enhancedSeries,
    }

    const {
        tooltipData,
        tooltipLeft,
        tooltipTop,
        tooltipOpen,
        tooltipHandler,
        defaultStyles,
        tooltipPortalRef,
        TooltipWrapper,
        DefaultTooltip,
    } = useTooltip(chartCtx, tooltipOptions)

    return (
        <Context.Provider
            value={{ ...chartCtx, tooltipData, tooltipLeft, tooltipTop, tooltipOpen }}
        >
            {/* Important: this is the ref element for tooltips, must be set to relative */}
            <div
                ref={tooltipPortalRef}
                className="relative w-full h-full"
                onPointerMove={tooltipHandler}
            >
                <svg width={width} height={height}>
                    {/* Primary y axis */}
                    {y1Axis ?? <AxisLeft />}

                    {/* Date axis  */}
                    {xAxis ?? <AxisBottom interval={interval} />}

                    {/* Horizontal, dotted lines at each y value tick mark */}
                    <GridRows
                        width={width - margin.left - margin.right}
                        left={margin.left}
                        scale={y1Scale}
                        numTicks={11}
                        stroke="currentColor"
                        strokeDasharray="1 8"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        className="text-gray-400"
                    />

                    {/* Vertical line for tooltip hover */}
                    {tooltipOpen && tooltipData && (
                        <Line
                            x1={tooltipLeft}
                            x2={tooltipLeft}
                            y1={margin.top}
                            y2={height - margin.bottom}
                            strokeWidth={2}
                            stroke="currentColor"
                            strokeOpacity={0.5}
                            className="text-gray-200"
                        />
                    )}

                    {/* Pass chart context as render props so arbitrary SVG elements can be passed as children and use ctx as inputs */}
                    {typeof children === 'function'
                        ? children({
                              ...chartCtx,
                              tooltipOpen,
                              tooltipData,
                              tooltipLeft,
                              tooltipTop,
                          })
                        : children}
                </svg>

                {/* Must render tooltip outside of SVG since it renders as div  */}
                {tooltipOpen && tooltipData && (
                    <TooltipWrapper
                        key={Math.random()} // needed for bounds to update correctly (see - https://airbnb.io/visx/tooltip)
                        left={tooltipLeft}
                        top={tooltipTop}
                        style={{
                            ...defaultStyles,
                            backgroundColor: 'transparent',
                        }}
                        offsetLeft={tooltipOptions?.offsetX}
                        offsetTop={tooltipOptions?.offsetY}
                    >
                        {renderTooltip ? (
                            renderTooltip(tooltipData)
                        ) : (
                            <DefaultTooltip title={tooltipOptions?.tooltipTitle} />
                        )}
                    </TooltipWrapper>
                )}
            </div>
        </Context.Provider>
    )
}
