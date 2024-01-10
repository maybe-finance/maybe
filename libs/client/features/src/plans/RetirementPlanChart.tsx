import type { SharedType } from '@maybe-finance/shared'
import { PlanUtil } from '@maybe-finance/shared'
import { DateUtil, NumberUtil } from '@maybe-finance/shared'
import { TSeries } from '@maybe-finance/client/shared'
import { Group } from '@visx/group'
import { DateTime } from 'luxon'
import { useCallback, useMemo } from 'react'
import { usePlanContext } from './PlanContext'
import { getMilestoneIcon, getEventIcon } from './icon-utils'
import { FractionalCircle } from '@maybe-finance/design-system'
import classNames from 'classnames'
import take from 'lodash/take'

type Props = {
    isLoading: boolean
    isError: boolean
    dateRange: SharedType.DateRange<DateTime> // date range in years
    retirement: {
        milestone: SharedType.PlanProjectionMilestone
        projection: SharedType.PlanProjectionData
    } | null
    maxStackCount: number // determines the max number of icons for a single year (for chart padding)
    data?: SharedType.PlanProjectionResponse
    onAddEvent: (date: string) => void
    failsEarly: boolean
    mode: 'age' | 'year'
}

const MAX_ICONS_PER_DATUM = 4

export function RetirementPlanChart({
    isLoading,
    isError,
    data,
    dateRange,
    retirement,
    onAddEvent,
    maxStackCount,
    failsEarly,
    mode,
}: Props) {
    const { userAge } = usePlanContext()

    const getDatumIcons = useCallback<
        (date: string) => {
            events: SharedType.PlanProjectionData['values']['events']
            milestones: SharedType.PlanProjectionData['values']['milestones']
        } | null
    >(
        (date) => {
            const currentDatum = data?.projection.data.find((d) => d.date === date)

            if (!currentDatum) return null

            const events =
                currentDatum.values.events.filter((d) => {
                    const eventStartYear =
                        d.event.startYear ??
                        PlanUtil.resolveMilestoneYear(data!.projection, d.event.startMilestoneId!)

                    const eventEndYear =
                        d.event.endYear ??
                        PlanUtil.resolveMilestoneYear(data!.projection, d.event.endMilestoneId!)

                    return (
                        eventStartYear === currentDatum.values.year ||
                        eventEndYear === currentDatum.values.year
                    )
                }) ?? []

            const milestones = currentDatum?.values.milestones ?? []

            return {
                events,
                milestones,
            }
        },
        [data]
    )

    const colorAccessorFn = useCallback<
        TSeries.AccessorFn<SharedType.PlanProjectionData['values'], string>
    >(
        (datum) => {
            if (failsEarly) {
                return TSeries.tailwindScale('red')
            }

            if (!retirement) {
                return TSeries.tailwindScale('cyan')
            }

            const retirementIdx = data?.projection.data.findIndex(
                (d) => d.date === retirement.projection.date
            )
            const datumIdx = data?.projection.data.findIndex((d) => d.date === datum.date)

            if (!retirementIdx || !datumIdx || retirementIdx < 0 || datumIdx < 0) {
                return TSeries.tailwindScale('cyan')
            }

            return datumIdx <= retirementIdx
                ? TSeries.tailwindScale('cyan')
                : TSeries.tailwindScale('grape')
        },
        [data?.projection.data, retirement, failsEarly]
    )

    const chartData = useMemo(() => {
        function showDate(date: string) {
            const _date = DateTime.fromISO(date)
            const { start, end } = dateRange
            return _date >= start && _date <= end
        }

        const projection = data?.projection.data.filter((datum) => showDate(datum.date))

        if (!projection || !data?.simulations.length) return undefined

        const lowerProjection = data?.simulations[0]?.simulation.data.filter((datum) =>
            showDate(datum.date)
        )
        const upperProjection = data?.simulations[
            data.simulations.length - 1
        ]?.simulation.data.filter((datum) => showDate(datum.date))

        if (!upperProjection || !lowerProjection) return undefined

        return {
            projection: projection,
            upperProjection: upperProjection,
            lowerProjection: lowerProjection,
        }
    }, [data, dateRange])

    return (
        <TSeries.Chart<SharedType.PlanProjectionData['values']>
            id="retirement-chart"
            isLoading={isLoading}
            isError={isError || (!chartData && !isLoading)}
            dateRange={{
                start: dateRange.start.toISODate(),
                end: dateRange.end.toISODate(),
            }}
            margin={{ top: 20, right: 20 }}
            padding={{
                top:
                    0.125 *
                    (maxStackCount > MAX_ICONS_PER_DATUM ? MAX_ICONS_PER_DATUM : maxStackCount),
            }} // 12.5% padding for each additional stacked icon, up to 4 total icons max
            interval={data?.projection.interval}
            series={[
                {
                    key: 'portfolio',
                    dataKey: 'projection',
                    accessorFn: (d) => d.values.netWorth?.toNumber(),
                    color: colorAccessorFn,
                },
                {
                    key: 'portfolio-upper-range',
                    dataKey: 'upperProjection',
                    accessorFn: (d) => d.values.netWorth?.toNumber(),
                },
                {
                    key: 'portfolio-lower-range',
                    dataKey: 'lowerProjection',
                    accessorFn: (d) => d.values.netWorth?.toNumber(),
                },
            ]}
            data={chartData}
            tooltipOptions={{
                referenceSeriesKey: 'portfolio',
            }}
            xAxis={
                <TSeries.AxisBottom
                    interval={data?.projection.interval}
                    tickFormat={(d) =>
                        mode === 'age'
                            ? DateUtil.yearToAge(
                                  +DateTime.fromJSDate(d as Date, { zone: 'utc' }).toFormat('yyyy'),
                                  userAge
                              ).toString()
                            : DateTime.fromJSDate(d as Date, { zone: 'utc' }).toFormat('yyyy')
                    }
                />
            }
            renderTooltip={(tooltipData) => {
                if (!tooltipData) return null

                const [main, upper, lower] = tooltipData.values
                const icons = getDatumIcons(tooltipData.date)

                const datumYear = +DateTime.fromISO(tooltipData.date, { zone: 'utc' }).toFormat(
                    'yyyy'
                )

                const successRate =
                    tooltipData.series?.['portfolio'].originalDatum.values.successRate

                return (
                    <div className="flex flex-col gap-2 text-gray-25 text-base w-[250px]">
                        <div className="bg-gray-700 border border-gray-600 rounded p-2 space-y-1">
                            <p className="text-gray-100">
                                {datumYear}
                                {` (age ${DateUtil.yearToAge(datumYear, userAge)})`}
                            </p>
                            <div className="flex items-center gap-1">
                                <span className="w-1 h-3 bg-cyan mr-2 inline-block rounded-sm" />
                                <span>Projected net worth</span>
                                <span className="ml-auto">
                                    {NumberUtil.format(main, 'short-currency')}
                                </span>
                            </div>
                            <p className="text-gray-100">
                                Range:{' '}
                                {NumberUtil.format(lower, 'short-currency', {
                                    minimumFractionDigits: 0,
                                    maximumFractionDigits: 1,
                                })}
                                {' to '}
                                {NumberUtil.format(upper, 'short-currency', {
                                    minimumFractionDigits: 0,
                                    maximumFractionDigits: 1,
                                })}
                            </p>

                            {successRate && (
                                <div
                                    className={classNames(
                                        'flex items-center gap-2',
                                        successRate.greaterThanOrEqualTo(0.95)
                                            ? 'text-teal'
                                            : successRate.greaterThanOrEqualTo(0.7)
                                            ? 'text-yellow'
                                            : 'text-red'
                                    )}
                                >
                                    <FractionalCircle
                                        percent={successRate.times(100).toNumber()}
                                        variant={
                                            successRate.greaterThanOrEqualTo(0.95)
                                                ? 'green'
                                                : successRate.greaterThanOrEqualTo(0.7)
                                                ? 'yellow'
                                                : 'red'
                                        }
                                    />

                                    <span>
                                        {NumberUtil.format(successRate, 'percent', {
                                            signDisplay: 'auto',
                                        })}{' '}
                                        survival rate
                                    </span>
                                </div>
                            )}
                        </div>
                        {icons && icons.milestones.length > 0 && (
                            <div className="bg-gray-700 border border-gray-600 rounded p-2 space-y-2">
                                {icons.milestones.map((milestone) => {
                                    const milestoneIcon = getMilestoneIcon(milestone)

                                    return (
                                        <div className="flex items-center gap-2" key={milestone.id}>
                                            <div
                                                className="flex items-center justify-center w-6 h-6 rounded-full"
                                                style={{
                                                    backgroundColor: milestoneIcon.bgColor,
                                                }}
                                            >
                                                <milestoneIcon.icon
                                                    className="w-4 h-4 text-cyan"
                                                    style={{ color: milestoneIcon.color }}
                                                />
                                            </div>
                                            <span>{milestoneIcon.label}</span>
                                        </div>
                                    )
                                })}
                            </div>
                        )}
                        {icons && icons.events.length > 0 && chartData?.projection && (
                            <div className="bg-gray-700 border border-gray-600 rounded p-2 space-y-2">
                                {icons.events.map((event) => {
                                    if (!data?.projection) return null

                                    const eventIcon = getEventIcon(
                                        event,
                                        data.projection,
                                        datumYear
                                    )

                                    return (
                                        <div
                                            className="flex items-center gap-2"
                                            key={event.event.id}
                                        >
                                            <div
                                                className="flex items-center justify-center w-6 h-6 rounded-full"
                                                style={{ backgroundColor: eventIcon.bgColor }}
                                            >
                                                <eventIcon.icon
                                                    className="w-4 h-4"
                                                    style={{ color: eventIcon.color }}
                                                />
                                            </div>
                                            <span>{eventIcon.label}</span>
                                        </div>
                                    )
                                })}
                            </div>
                        )}
                    </div>
                )
            }}
        >
            {({ xScale, data: ctxData, tooltipOpen, tooltipData, y1Scale }) => {
                const upperData = Array.isArray(ctxData) ? ctxData : ctxData['upperProjection']

                return (
                    <>
                        <TSeries.LineRange
                            mainSeriesKey="portfolio"
                            lowerSeriesKey="portfolio-upper-range"
                            upperSeriesKey="portfolio-lower-range"
                            renderGlyph={(tooltipData, left, top) => {
                                return (
                                    <TSeries.PlusCircleGlyph
                                        className="cursor-pointer hover:opacity-90"
                                        fill={
                                            tooltipData.series?.['portfolio']
                                                ? colorAccessorFn(
                                                      tooltipData.series?.['portfolio']
                                                          .originalDatum
                                                  )
                                                : TSeries.tailwindScale('cyan')
                                        }
                                        stroke="black"
                                        left={left}
                                        top={top}
                                        onClick={() => onAddEvent(tooltipData.date)}
                                    />
                                )
                            }}
                        />

                        {/* Event icons - for proper SVG stacking order, keep these as the last children of the chart  */}
                        <Group>
                            {upperData.map((datum, idx) => {
                                const icons = getDatumIcons(datum.date)

                                // Place icon above the highest series value
                                const upperValue = datum.values.netWorth?.toNumber()

                                if (
                                    !upperValue ||
                                    !icons ||
                                    (!icons.events.length && !icons.milestones.length)
                                )
                                    return null

                                const isCurrent =
                                    tooltipOpen && tooltipData && tooltipData.date === datum.date

                                // Stack each event on top of each other if multiple events per datum
                                return (
                                    <Group key={idx}>
                                        {icons.milestones.map((milestone, iconIdx) => {
                                            const milestoneIcon = getMilestoneIcon(milestone)

                                            return (
                                                <TSeries.FloatingIcon
                                                    key={iconIdx}
                                                    left={xScale(datum.dateJS)}
                                                    top={y1Scale(upperValue) - 25}
                                                    stackIdx={iconIdx}
                                                    fill={
                                                        isCurrent
                                                            ? milestoneIcon.bgColor
                                                            : TSeries.tailwindBgScale('gray')
                                                    }
                                                    icon={milestoneIcon.icon}
                                                    iconColor={
                                                        isCurrent
                                                            ? milestoneIcon.color
                                                            : TSeries.tailwindScale('gray-100')
                                                    }
                                                />
                                            )
                                        })}

                                        {take(
                                            icons.events,
                                            MAX_ICONS_PER_DATUM - icons.milestones.length
                                        ).map((event, iconIdx) => {
                                            if (!data?.projection) return null

                                            const eventIcon = getEventIcon(
                                                event,
                                                data.projection,
                                                datum.values.year
                                            )

                                            return (
                                                <TSeries.FloatingIcon
                                                    key={iconIdx}
                                                    left={xScale(datum.dateJS)}
                                                    top={y1Scale(upperValue) - 25}
                                                    stackIdx={iconIdx + icons.milestones.length}
                                                    fill={
                                                        isCurrent
                                                            ? eventIcon.bgColor
                                                            : TSeries.tailwindBgScale('gray')
                                                    }
                                                    icon={eventIcon.icon}
                                                    iconColor={
                                                        isCurrent
                                                            ? eventIcon.color
                                                            : TSeries.tailwindScale('gray-100')
                                                    }
                                                />
                                            )
                                        })}
                                    </Group>
                                )
                            })}
                        </Group>
                    </>
                )
            }}
        </TSeries.Chart>
    )
}
