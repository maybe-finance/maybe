import type { Calendar, GetBackForwardPropsOptions } from 'dayzed'
import classNames from 'classnames'
import { RiArrowLeftSLine, RiArrowRightSLine } from 'react-icons/ri'

import { generateYearsRange, disabled } from './utils'

export interface DatePickerYearProps {
    calendars: Calendar[]
    getBackProps: (data: GetBackForwardPropsOptions) => Record<string, any>
    getForwardProps: (data: GetBackForwardPropsOptions) => Record<string, any>
    onYearSelected: () => void
    minDate: string
    maxDate: string
}

export function DatePickerYear({
    calendars,
    getBackProps,
    getForwardProps,
    onYearSelected,
    minDate,
    maxDate,
}: DatePickerYearProps) {
    const calendar = calendars[0]
    const selectedYear = calendar.year
    const years = generateYearsRange(selectedYear)

    const getYearProps = (year: number) => {
        if (year > calendar.year) {
            const forwardProps = getForwardProps({
                calendars,
                offset: (year - calendar.year) * 12,
                onClick: onYearSelected,
            })

            return {
                ...forwardProps,
                disabled: disabled({ year, maxDate }),
            }
        }

        const backProps = getBackProps({
            calendars,
            offset: (calendar.year - year) * 12,
            onClick: onYearSelected,
        })

        return {
            ...backProps,
            disabled: disabled({ year, minDate }),
        }
    }

    return (
        <div>
            <div className="flex justify-around gap-x-2">
                <button
                    className={classNames(
                        'text-white hover:bg-gray-500 flex justify-center items-center rounded w-8 h-8',
                        'disabled:opacity-50 disabled:pointer-events-none'
                    )}
                    type="button"
                    {...getBackProps({ calendars, offset: 12 * 12 })}
                >
                    <RiArrowLeftSLine size={24} />
                </button>
                <span className="text-white  flex justify-center items-center rounded grow">
                    {`${calendar.year - 5} - ${calendar.year + 6}`}
                </span>
                <button
                    className={classNames(
                        'text-white hover:bg-gray-500 flex justify-center items-center rounded w-8 h-8',
                        'disabled:opacity-50 disabled:pointer-events-none'
                    )}
                    type="button"
                    {...getForwardProps({ calendars, offset: 12 * 12 })}
                >
                    <RiArrowRightSLine size={24} />
                </button>
            </div>
            <div className="grid grid-cols-3 grid-rows-4 gap-2 mt-2">
                {years.map((year) => (
                    <button
                        {...getYearProps(year)}
                        key={year}
                        className={classNames(
                            'flex justify-center items-center rounded h-10 w-20',
                            'disabled:opacity-50 disabled:pointer-events-none',
                            year === selectedYear
                                ? 'bg-cyan-500 text-black hover:bg-cyan-400'
                                : 'text-white hover:bg-gray-500'
                        )}
                    >
                        {year}
                    </button>
                ))}
            </div>
        </div>
    )
}
