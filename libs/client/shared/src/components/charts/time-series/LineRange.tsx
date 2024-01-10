import type { Series, TooltipData } from './types'
import type { ReactNode } from 'react'

import { useMemo } from 'react'
import { useChartData } from './BaseChart'
import { Group } from '@visx/group'
import { LinePath } from '@visx/shape'
import { Threshold } from '@visx/threshold'
import { curveNatural } from '@visx/curve'
import { GlyphCircle } from '@visx/glyph'
import { MultiColorGradient } from './MultiColorGradient'
import { useSeries } from './useSeries'

export function LineRange({
    mainSeriesKey,
    lowerSeriesKey,
    upperSeriesKey,
    renderGlyph,
}: {
    mainSeriesKey: Series['key']
    lowerSeriesKey: Series['key']
    upperSeriesKey: Series['key']
    renderGlyph?: (tooltipData: TooltipData, left: number, top: number) => ReactNode
}) {
    const { xScale, y1Scale, tooltipData, tooltipLeft, margin, height } = useChartData()

    const mainSeries = useSeries(mainSeriesKey)

    const lowerSeries = useSeries(lowerSeriesKey)
    const upperSeries = useSeries(upperSeriesKey)

    const combinedData = useMemo(() => {
        return mainSeries.data.map((mainSeriesData) => {
            return {
                date: mainSeriesData.date,
                dateJS: mainSeriesData.dateJS,
                mainData: mainSeriesData,
                upperData: upperSeries.data.find((u) => u.date === mainSeriesData.date),
                lowerData: lowerSeries.data.find((l) => l.date === mainSeriesData.date),
            }
        })
    }, [mainSeries, lowerSeries, upperSeries])

    if (!mainSeries.isActive) return null

    if (
        mainSeries.isActive !== lowerSeries.isActive ||
        mainSeries.isActive !== upperSeries.isActive
    )
        throw new Error('All series in threshold must be active or inactive')

    return (
        <Group color={typeof mainSeries.color === 'string' ? mainSeries.color : undefined}>
            {/* Primary line path  */}
            <LinePath
                data={mainSeries.data}
                x={(datum) => xScale(datum.dateJS)}
                y={(datum) => {
                    const value = mainSeries.accessorFn(datum)
                    return y1Scale(value ?? 0)
                }}
                className="fill-transparent stroke-2"
                curve={curveNatural}
                stroke={mainSeries.lineColor}
                strokeLinejoin="round"
            />

            <Threshold
                id={Math.random().toString()}
                data={combinedData}
                x={(datum) => xScale(datum.dateJS)}
                y0={(datum) =>
                    y1Scale((datum.lowerData ? lowerSeries.accessorFn(datum.lowerData) : 0) ?? 0)
                }
                y1={(datum) =>
                    y1Scale((datum.upperData ? upperSeries.accessorFn(datum.upperData) : 0) ?? 0)
                }
                // Set to the entire vertical range of the chart (i.e. no clipping)
                clipAboveTo={0}
                clipBelowTo={height - margin.bottom}
                curve={curveNatural}
                className="opacity-10"
                aboveAreaProps={{ fill: mainSeries.lineColor }}
                belowAreaProps={{ fill: mainSeries.lineColor }}
            />

            {/* On hover, this glyph displays over the data point on the line, OR renders a custom glyph */}
            {/* Keep this at bottom to ensure proper stacking context */}
            {tooltipData && tooltipLeft && mainSeries.currentDatum ? (
                renderGlyph ? (
                    renderGlyph(tooltipData, tooltipLeft, y1Scale(mainSeries.currentDatum.value))
                ) : (
                    <GlyphCircle
                        left={tooltipLeft}
                        top={y1Scale(mainSeries.currentDatum.value)}
                        size={60}
                        strokeWidth={2}
                        fill={
                            typeof mainSeries.color === 'function'
                                ? mainSeries.color(mainSeries.currentDatum.datum)
                                : mainSeries.color
                        }
                    />
                )
            ) : null}

            {/* Multi colored line gradient (optional)  */}
            {/* Pass an accessor that evaluates each data point and determines what color to display around that point  */}
            {typeof mainSeries.color === 'function' && (
                <MultiColorGradient
                    id={`${mainSeries.seriesPrefix}-color-gradient`}
                    accessorFn={mainSeries.color}
                    dataKey={mainSeries.dataKey}
                />
            )}
        </Group>
    )
}
