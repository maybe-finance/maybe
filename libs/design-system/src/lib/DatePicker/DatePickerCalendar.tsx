import type { DateObj } from 'dayzed'
import classNames from 'classnames'
import { useDayzed } from 'dayzed'
import { DateTime, Info } from 'luxon'
import { useMemo, useState } from 'react'
import { RiArrowLeftSLine, RiArrowRightSLine } from 'react-icons/ri'
import { DatePickerMonth } from './DatePickerMonth'
import { DatePickerYear } from './DatePickerYear'

export interface DatePickerCalendarProps {
    date?: string
    onChange: (date: string) => void
    minDate: string
    maxDate: string
    controlButtons: React.ReactNode
}

export function DatePickerCalendar({
    date,
    onChange,
    minDate,
    maxDate,
    controlButtons,
}: DatePickerCalendarProps) {
    const { currentCalendarDate, currentCalendarSelection } = useMemo(() => {
        if (!date)
            return { currentCalendarDate: DateTime.now().toJSDate(), currentCalendarSelection: [] }

        return {
            currentCalendarDate: DateTime.fromISO(date).toJSDate(),
            currentCalendarSelection: DateTime.fromISO(date).toJSDate(),
        }
    }, [date])

    const [offset, setOffset] = useState(0)

    const { calendars, getBackProps, getForwardProps, getDateProps } = useDayzed({
        date: currentCalendarDate, // determines what month to show
        selected: currentCalendarSelection,
        onDateSelected: (dateObj: DateObj) => {
            setOffset(0)
            onChange(DateTime.fromJSDate(dateObj.date).toISODate() || '')
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
                                calendar.weeks.length < 6 && 'gap-y-2 pb-4'
                            )}
                        >
                            {/* Day names row */}
                            <div className="contents text-base text-gray-100 text-center">
                                {/* Rotate Info.weekdays +6 to start with Sunday */}
                                {[...Array(7)].map((_, day) => (
                                    <div key={`${calendar.year}-${calendar.month}-${day}`}>
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
                                                return (
                                                    <div
                                                        key={`${calendar.year}-${calendar.month}-${weekIndex}-${dateIndex}`}
                                                        className={classNames('relative px-1.5')}
                                                    >
                                                        {/* Date button */}
                                                        <button
                                                            key={`${calendar.year}-${calendar.month}-${weekIndex}-${dateIndex}`}
                                                            disabled={!dateObj.selectable}
                                                            type="button"
                                                            className={classNames(
                                                                'w-10 h-10 rounded-full text-center',
                                                                'disabled:opacity-50 disabled:pointer-events-none',
                                                                'focus:outline-none focus:ring focus:ring-gray-200 focus:ring-opacity-50',
                                                                dateObj.today && 'font-semibold',
                                                                dateObj.selected
                                                                    ? 'bg-cyan text-black'
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
