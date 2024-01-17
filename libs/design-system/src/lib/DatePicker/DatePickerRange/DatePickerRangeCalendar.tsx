import type { DateRange } from '../selectableRanges'
import type { DateObj } from 'dayzed'
import { useDayzed } from 'dayzed'
import classNames from 'classnames'
import { DateTime, Info } from 'luxon'
import { useMemo, useState } from 'react'
import { RiArrowLeftSLine, RiArrowRightSLine } from 'react-icons/ri'

import { DatePickerMonth } from '../DatePickerMonth'
import { DatePickerYear } from '../DatePickerYear'

export interface DatePickerRangeCalendarProps {
    range?: Partial<DateRange>
    onChange: (range: Partial<DateRange>) => void
    minDate: string
    maxDate: string
    rangeInputs: React.ReactNode
    controlButtons: React.ReactNode
}

export function DatePickerRangeCalendar({
    range,
    onChange,
    minDate,
    maxDate,
    rangeInputs,
    controlButtons,
}: DatePickerRangeCalendarProps) {
    const { currentCalendarDate, currentCalendarSelection } = useMemo(() => {
        if (!range)
            return { currentCalendarDate: DateTime.now().toJSDate(), currentCalendarSelection: [] }

        const dates: Date[] = []

        if (range.start) {
            dates.push(DateTime.fromISO(range.start).toJSDate())
        }

        if (range.end) {
            dates.push(DateTime.fromISO(range.end).toJSDate())
        }

        return {
            currentCalendarDate: DateTime.fromISO(
                range.start && range.end ? range.end! : range.start!
            ).toJSDate(),
            currentCalendarSelection: dates,
        }
    }, [range])

    const [offset, setOffset] = useState(0)

    const { calendars, getBackProps, getForwardProps, getDateProps } = useDayzed({
        date: currentCalendarDate, // determines what month to show
        selected: currentCalendarSelection,
        onDateSelected: (dateObj: DateObj) => {
            const date = DateTime.fromJSDate(dateObj.date)
            const start = range && range.start ? DateTime.fromISO(range.start) : undefined
            const end = range && range.end ? DateTime.fromISO(range.end) : undefined

            // We always want the calendar reflecting the most recently selected date (regardless of whether that date is
            // the beginning or end of the range selection).  An offset should only exist *between* user clicks.
            setOffset(0)

            // Start the range process over
            if ((start && end) || !start || (start && date < start)) {
                onChange({ start: date.toISODate(), end: undefined })

                return
            }

            onChange({ start: range!.start, end: date.toISODate() })
        },
        minDate: DateTime.fromISO(minDate).toJSDate(),
        maxDate: DateTime.fromISO(maxDate).toJSDate(),
        offset,
        onOffsetChanged: setOffset,
    })

    const [view, setView] = useState<'calendar' | 'month' | 'year'>('calendar')

    return (
        <div>
            {view === 'calendar' && (
                <div className="flex rounded gap-2">
                    {/* Back button (- 1 month) */}
                    <button
                        {...getBackProps({ calendars })}
                        className="text-gray-50 hover:text-white hover:bg-gray-500 flex justify-center items-center rounded w-10 h-10 disabled:opacity-50 disabled:pointer-events-none"
                        data-testid="datepicker-range-back-arrow"
                    >
                        <RiArrowLeftSLine size={24} />
                    </button>

                    {/* Displays the calendar's current month and year */}
                    <div className="flex grow justify-around gap-2">
                        <button
                            className="text-white hover:bg-gray-500 flex grow justify-center items-center rounded uppercase"
                            data-testid="datepicker-range-month-button"
                            onClick={() => setView('month')}
                        >
                            {Info.months('short')[calendars[0].month]}
                        </button>
                        <button
                            className="text-white hover:bg-gray-500 flex grow justify-center items-center rounded"
                            data-testid="datepicker-range-year-button"
                            onClick={() => setView('year')}
                        >
                            {calendars[0].year}
                        </button>
                    </div>

                    {/* Forward button (+ 1 month) */}
                    <button
                        {...getForwardProps({ calendars })}
                        className="text-gray-50 hover:text-white hover:bg-gray-500 flex justify-center items-center rounded w-10 h-10 disabled:opacity-50 disabled:pointer-events-none"
                        data-testid="datepicker-range-next-arrow"
                    >
                        <RiArrowRightSLine size={24} />
                    </button>
                </div>
            )}
            {view === 'calendar' && rangeInputs}
            <div className="mt-2">
                {view === 'month' && (
                    <DatePickerMonth
                        calendars={calendars}
                        getBackProps={getBackProps}
                        getForwardProps={getForwardProps}
                        onMonthSelected={() => setView('calendar')}
                    />
                )}
                {view === 'year' && (
                    <DatePickerYear
                        minDate={minDate}
                        maxDate={maxDate}
                        calendars={calendars}
                        getBackProps={getBackProps}
                        getForwardProps={getForwardProps}
                        onYearSelected={() => setView('calendar')}
                    />
                )}
                {view === 'calendar' &&
                    calendars.map((calendar) => (
                        <div
                            key={`${calendar.year}-${calendar.month}`}
                            className={classNames(
                                'grid grid-cols-7 gap-y-1',
                                calendar.weeks.length < 6 && 'gap-y-1 pb-4'
                            )}
                        >
                            {/* Day names row */}
                            <div className="contents text-base text-gray-100 text-center">
                                {/* Rotate Info.weekdays +6 to start with Sunday */}
                                {[...Array(7)].map((_, day) => (
                                    <div
                                        key={`${calendar.year}-${calendar.month}-${day}`}
                                        className="my-1"
                                    >
                                        {Info.weekdays('short')[(day + 6) % 7]}
                                    </div>
                                ))}
                            </div>

                            {/* Date cells */}
                            <div className="contents text-base text-white" data-testid="day-cells">
                                {calendar.weeks.map((week, weekIndex) => (
                                    <div
                                        className="contents"
                                        key={`${calendar.year}-${calendar.month}-${weekIndex}`}
                                    >
                                        {week.map((dateObj, dateIndex) => {
                                            if (dateObj) {
                                                const d = DateTime.fromJSDate(dateObj.date)

                                                const start =
                                                    range && range.start
                                                        ? DateTime.fromISO(range.start)
                                                        : undefined

                                                const end =
                                                    range && range.end
                                                        ? DateTime.fromISO(range.end)
                                                        : undefined

                                                const hasBothDates = !!start && !!end
                                                const inRange = start && end && d > start && d < end
                                                const isEnd =
                                                    end && d.toISODate() === end.toISODate()
                                                const isStart =
                                                    start && d.toISODate() === start.toISODate()

                                                const isFirstWeekday = dateObj.date.getDay() === 0
                                                const isLastWeekday = dateObj.date.getDay() === 6
                                                const isFirstDayOfMonth =
                                                    dateObj.date.getDate() === 1
                                                const isLastDayOfMonth =
                                                    dateObj.date.getDate() ===
                                                    calendar.lastDayOfMonth.getDate()

                                                return (
                                                    <div
                                                        key={`${calendar.year}-${calendar.month}-${weekIndex}-${dateIndex}`}
                                                        className={classNames(
                                                            'relative px-1.5',
                                                            inRange &&
                                                                !dateObj.selected &&
                                                                classNames(
                                                                    'bg-gray-600',
                                                                    (isFirstWeekday ||
                                                                        isFirstDayOfMonth) &&
                                                                        'rounded-l-full',
                                                                    (isLastWeekday ||
                                                                        isLastDayOfMonth) &&
                                                                        'rounded-r-full'
                                                                )
                                                        )}
                                                    >
                                                        {hasBothDates &&
                                                            ((isStart &&
                                                                !isLastWeekday &&
                                                                !isLastDayOfMonth) ||
                                                                (isEnd &&
                                                                    !isFirstWeekday &&
                                                                    !isFirstDayOfMonth)) &&
                                                            start.toISODate() !==
                                                                end.toISODate() && (
                                                                <>
                                                                    {/* Fills background color gap for cells at ends of range */}
                                                                    <div
                                                                        className={classNames(
                                                                            'absolute -z-10 w-1/2 h-full bg-gray-600',
                                                                            isStart
                                                                                ? 'left-1/2'
                                                                                : 'left-0'
                                                                        )}
                                                                    ></div>
                                                                </>
                                                            )}
                                                        {/* Actual date button */}
                                                        <button
                                                            key={`${calendar.year}-${calendar.month}-${weekIndex}-${dateIndex}`}
                                                            disabled={!dateObj.selectable}
                                                            className={classNames(
                                                                'w-10 h-10 rounded-full text-center',
                                                                'disabled:opacity-50 disabled:pointer-events-none',
                                                                'focus:outline-none focus:ring focus:ring-gray-200 focus:ring-opacity-50',
                                                                dateObj.today && 'font-semibold',
                                                                isStart || isEnd
                                                                    ? 'bg-cyan text-black'
                                                                    : inRange
                                                                    ? 'bg-gray-600'
                                                                    : 'hover:bg-gray-600'
                                                            )}
                                                            {...getDateProps({
                                                                dateObj,
                                                            })}
                                                        >
                                                            {dateObj.date.getDate()}
                                                        </button>
                                                    </div>
                                                )
                                            }

                                            // Empty cell
                                            return (
                                                <div
                                                    key={`${calendar.year}-${calendar.month}-${weekIndex}-${dateIndex}`}
                                                ></div>
                                            )
                                        })}
                                    </div>
                                ))}
                            </div>
                        </div>
                    ))}
            </div>

            {view === 'calendar' && controlButtons}
        </div>
    )
}
