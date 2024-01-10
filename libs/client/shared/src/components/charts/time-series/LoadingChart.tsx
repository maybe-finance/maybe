import type { Spacing, RenderOverlay } from './types'

import { Button } from '@maybe-finance/design-system'
import { DateUtil } from '@maybe-finance/shared'
import { AxisBottom, AxisLeft } from '@visx/axis'
import { GridRows } from '@visx/grid'
import { ParentSize } from '@visx/responsive'
import { scaleLinear, scaleUtc } from '@visx/scale'
import { AreaClosed } from '@visx/shape'
import { motion } from 'framer-motion'
import { DateTime } from 'luxon'

type Props = {
    margin: Spacing
    renderOverlay?: RenderOverlay
    animate?: boolean
    isError?: boolean
}

const dates = DateUtil.generateDailySeries(
    DateTime.utc().toISODate(),
    DateTime.utc().plus({ months: 2 }).toISODate()
)

const values = [
    59, 61, 62, 60, 65, 68, 68, 61, 52, 55, 56, 51, 48, 50, 44, 41, 48, 50, 50, 52, 60, 61, 62, 63,
    62, 63, 70, 71, 67, 67, 65, 67, 65, 62, 57, 61, 63, 58, 61, 58, 59, 58, 56, 58, 55, 60, 58, 67,
    71, 76, 74, 78, 77, 79, 75, 79, 79, 81, 87, 89, 88, 89, 90,
]

const data = dates.map((date, idx) => ({
    date: DateTime.fromISO(date).toJSDate(),
    value: values[idx],
}))

export function LoadingChart({ margin, animate = true, isError = false, renderOverlay }: Props) {
    return (
        <ParentSize className="relative">
            {({ width, height }) => {
                const xScale = scaleUtc({
                    domain: [
                        DateTime.fromISO(dates[0]).toJSDate(),
                        DateTime.fromISO(dates[dates.length - 1]).toJSDate(),
                    ],
                    range: [margin.left, width - margin.right],
                })
                const yScale = scaleLinear({
                    domain: [0, 100],
                    range: [height - margin.bottom, margin.top],
                })

                return (
                    <>
                        {(isError || renderOverlay != null) && (
                            <div
                                className="absolute bg-black w-full h-full inset-0 bg-opacity-80 rounded flex gap-3 flex-col items-center justify-center"
                                style={{
                                    left: margin.left,
                                    top: margin.top,
                                    width: width - margin.right - margin.left,
                                    height: height - margin.top - margin.bottom,
                                }}
                            >
                                {renderOverlay != null ? (
                                    renderOverlay()
                                ) : (
                                    <>
                                        <h2>Oops!</h2>
                                        <p className="text-gray-100">
                                            Something went wrong. Try again?
                                        </p>
                                        <Button onClick={() => window.location.reload()}>
                                            Reload
                                        </Button>
                                    </>
                                )}
                            </div>
                        )}
                        <svg width={width} height={height}>
                            <AxisLeft
                                scale={yScale}
                                left={margin.left}
                                hideAxisLine
                                hideTicks
                                numTicks={1}
                                axisClassName="text-gray-100"
                                tickFormat={(d, idx) => (idx === 0 ? '$0.00' : '∞')}
                                tickLabelProps={() => ({
                                    fill: 'currentColor',
                                    textAnchor: 'end',
                                    verticalAnchor: 'middle',
                                    fontSize: 12,
                                })}
                            />

                            <AxisBottom
                                scale={xScale}
                                top={height - margin.bottom}
                                hideTicks
                                hideAxisLine
                                axisClassName="text-gray-100"
                                tickValues={[data[0].date, data[data.length - 1].date]}
                                tickFormat={(date) =>
                                    DateTime.fromJSDate(date as Date).toFormat('MMM d, yyyy')
                                }
                                tickLabelProps={(_data, index, arr) => {
                                    return {
                                        fill: 'currentColor',
                                        textAnchor:
                                            index === arr.length - 1
                                                ? 'end'
                                                : index === 0
                                                ? 'start'
                                                : 'middle',
                                        verticalAnchor: 'middle',
                                        fontSize: 12,
                                    }
                                }}
                            />

                            <GridRows
                                width={width - margin.left - margin.right}
                                left={margin.left}
                                scale={yScale}
                                numTicks={10}
                                stroke="currentColor"
                                strokeDasharray="1 8"
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                className="text-gray-500"
                            />

                            <AreaClosed
                                yScale={yScale}
                                data={data}
                                x={(datum) => xScale(datum.date)}
                                y={(datum) => yScale(datum.value)}
                                className="text-gray-700"
                                fill="currentColor"
                            />

                            <AreaClosed
                                yScale={yScale}
                                data={data}
                                x={(datum) => xScale(datum.date)}
                                y={(datum) => yScale(datum.value)}
                                fill={
                                    animate && renderOverlay == null
                                        ? 'url(#placeholder-gradient)'
                                        : '#232428'
                                }
                            />

                            {/* Animated shine gradient (should match 'bg-shine animate-shine') */}
                            <motion.linearGradient
                                className="text-white"
                                id="placeholder-gradient"
                                animate={{
                                    gradientTransform: ['translate(-1, 0)', 'translate(1, 0)'],
                                }}
                                transition={{
                                    duration: 1.8,
                                    repeat: Infinity,
                                }}
                            >
                                <stop offset="0%" stopColor="currentColor" stopOpacity="0" />
                                <stop offset="25%" stopColor="currentColor" stopOpacity="0" />
                                <stop offset="50%" stopColor="currentColor" stopOpacity="0.07" />
                                <stop offset="75%" stopColor="currentColor" stopOpacity="0" />
                                <stop offset="100%" stopColor="currentColor" stopOpacity="0" />
                            </motion.linearGradient>
                        </svg>
                    </>
                )
            }}
        </ParentSize>
    )
}
