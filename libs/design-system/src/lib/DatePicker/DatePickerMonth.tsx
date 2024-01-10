import type { Calendar, GetBackForwardPropsOptions } from 'dayzed'
import classNames from 'classnames'
import { Info } from 'luxon'
import { useMemo } from 'react'
import { RiArrowLeftSLine, RiArrowRightSLine } from 'react-icons/ri'

export interface DatePickerMonthProps {
    calendars: Calendar[]
    getBackProps: (data: GetBackForwardPropsOptions) => Record<string, any>
    getForwardProps: (data: GetBackForwardPropsOptions) => Record<string, any>
    onMonthSelected: () => void
}

export function DatePickerMonth({
    calendars,
    getBackProps,
    getForwardProps,
    onMonthSelected,
}: DatePickerMonthProps) {
    const calendar = calendars[0]

    const selectedMonth = useMemo(() => `${calendar.year}/${calendar.month}`, [])

    const getMonthProps = (month: number) => {
        if (month > calendar.month) {
            return getForwardProps({
                calendars,
                offset: month - calendar.month,
                onClick: onMonthSelected,
            })
        }

        return getBackProps({ calendars, offset: calendar.month - month, onClick: onMonthSelected })
    }

    const months = Info.months('short')

    return (
        <div>
            <div className="flex justify-around gap-x-2">
                <button
                    className={classNames(
                        'text-white hover:bg-gray-500 flex justify-center items-center rounded w-8 h-8',
                        'disabled:opacity-50 disabled:pointer-events-none'
                    )}
                    type="button"
                    {...getBackProps({ calendars, offset: 12 })}
                >
                    <RiArrowLeftSLine size={24} />
                </button>
                <span className="text-white  flex justify-center items-center rounded grow">
                    {calendar.year}
                </span>
                <button
                    className={classNames(
                        'text-white hover:bg-gray-500 flex justify-center items-center rounded w-8 h-8',
                        'disabled:opacity-50 disabled:pointer-events-none'
                    )}
                    type="button"
                    {...getForwardProps({ calendars, offset: 12 })}
                >
                    <RiArrowRightSLine size={24} />
                </button>
            </div>
            <div className="grid grid-cols-3 grid-rows-4 gap-2 mt-2">
                {months.map((month, index) => (
                    <button
                        {...getMonthProps(index)}
                        key={month}
                        className={classNames(
                            'flex justify-center items-center rounded h-10 w-20',
                            'disabled:opacity-50 disabled:pointer-events-none',
                            `${calendar.year}/${index}` === selectedMonth
                                ? 'bg-cyan-500 text-black hover:bg-cyan-400'
                                : 'text-white hover:bg-gray-500'
                        )}
                    >
                        {month}
                    </button>
                ))}
            </div>
        </div>
    )
}
