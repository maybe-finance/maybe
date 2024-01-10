import type { Series, TooltipData, TSeriesDatumEnhanced } from './types'
import type { SVGProps, ReactNode } from 'react'

import { useChartData } from './BaseChart'
import { AreaClosed, LinePath } from '@visx/shape'
import { Group } from '@visx/group'
import { GlyphCircle } from '@visx/glyph'
import { MultiColorGradient } from './MultiColorGradient'
import { ZeroPointGradient } from './ZeroPointGradient'
import { useSeries } from './useSeries'
import classNames from 'classnames'

export function Line({
    seriesKey,
    renderGlyph,
    gradientOpacity = 0.2,
    interpolateLineProps,
    ...rest
}: {
    seriesKey: Series['key']

    /* Default line and gradient color class */
    gradientOpacity?: number

    /* Overrides the default circle glyph on hover */
    renderGlyph?: (tooltipData: TooltipData, left: number, top: number) => ReactNode

    /* SVG LinePath props for the interpolated line */
    interpolateLineProps?: Omit<SVGProps<SVGPathElement>, 'x' | 'y' | 'children'>
} & Omit<SVGProps<SVGPathElement>, 'x' | 'y' | 'children'>) {
    const { xScale, y1Scale, tooltipLeft, tooltipData } = useChartData()

    const {
        data,
        dataKey,
        color,
        accessorFn,
        isActive,
        isDefinedAccessor,
        hasUndefinedSegments,
        lineColor,
        seriesPrefix,
        currentDatum,
    } = useSeries(seriesKey)

    if (!isActive) return null

    return (
        <Group color={typeof color === 'string' ? color : undefined}>
            <>
                {/* Displays a dashed line to represent missing data (null, undefined, Infinity, or NaN values)  */}
                {hasUndefinedSegments && (
                    <LinePath
                        data={data.filter(isDefinedAccessor)}
                        x={(datum) => xScale(datum.dateJS)}
                        y={(datum) => {
                            const value = accessorFn(datum)
                            return y1Scale(value!)
                        }}
                        className={classNames('fill-transparent stroke-2 opacity-50')}
                        stroke={lineColor}
                        strokeLinejoin="round"
                        {...interpolateLineProps}
                    />
                )}

                {/* Primary line path  */}
                <LinePath
                    data={data}
                    // Some sort of bug here - must define the datum type otherwise TS compiler throws error
                    x={(datum: TSeriesDatumEnhanced) => xScale(datum.dateJS)}
                    y={(datum) => {
                        const value = accessorFn(datum)
                        return y1Scale(value ?? 0)
                    }}
                    className={classNames('fill-transparent stroke-2')}
                    stroke={lineColor}
                    // Leave a blank space for data gaps (will be represented as dashed stroke above)
                    defined={isDefinedAccessor}
                    strokeLinejoin="round"
                    {...rest}
                />

                {gradientOpacity && !hasUndefinedSegments && (
                    <Group>
                        <AreaClosed
                            yScale={y1Scale}
                            data={data}
                            // Fill will start where the y axis equals 0 and move *towards* the line
                            y0={y1Scale(0)}
                            x={(datum) => xScale(datum.dateJS)}
                            y={(datum) => {
                                const value = accessorFn(datum)
                                return y1Scale(value ?? 0)
                            }}
                            fillOpacity={0.5}
                            fill={`url(#${seriesPrefix}-zero-point-gradient)`}
                        />
                        <ZeroPointGradient
                            id={`${seriesPrefix}-zero-point-gradient`}
                            opacity={gradientOpacity}
                        />
                    </Group>
                )}

                {/* On hover, this glyph displays over the data point on the line, OR renders a custom glyph */}
                {/* Keep this at bottom to ensure proper stacking context */}
                {tooltipLeft && tooltipData && currentDatum ? (
                    renderGlyph ? (
                        renderGlyph(tooltipData, tooltipLeft, y1Scale(currentDatum.value))
                    ) : (
                        <GlyphCircle
                            left={tooltipLeft}
                            top={y1Scale(currentDatum.value)}
                            size={60}
                            strokeWidth={2}
                            fill={typeof color === 'function' ? color(currentDatum.datum) : color}
                        />
                    )
                ) : null}

                {/* Multi colored line gradient (optional)  */}
                {/* Pass an accessor that evaluates each data point and determines what color to display around that point  */}
                {typeof color === 'function' && (
                    <MultiColorGradient
                        id={`${seriesPrefix}-color-gradient`}
                        accessorFn={color}
                        dataKey={dataKey}
                    />
                )}
            </>
        </Group>
    )
}
