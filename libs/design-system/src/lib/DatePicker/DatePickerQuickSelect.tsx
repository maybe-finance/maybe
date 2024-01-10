import type { DateRange, SelectableDateRange } from './selectableRanges'
import { RadioGroup } from '@headlessui/react'
import classNames from 'classnames'
import { DateTime } from 'luxon'
import { useMemo } from 'react'

interface DatePickerQuickSelectProps {
    ranges: SelectableDateRange[]
    value?: Partial<DateRange>
    onChange: (range: DateRange) => void
}

export function DatePickerQuickSelect({ ranges, value, onChange }: DatePickerQuickSelectProps) {
    const optionStyle = 'pl-2 pr-8 py-1.5 rounded'

    const daysSelected = useMemo(() => {
        if (!value || !value.start || !value.end) return ''

        const start = DateTime.fromISO(value.start)
        const end = DateTime.fromISO(value.end)

        const diffDays = end.diff(start, 'days').days
        const diffMonths = end.diff(start, 'months').months
        const diffYears = end.diff(start, 'years').years

        if (diffDays <= 90) {
            return `Selected: ${Math.ceil(diffDays + 1)} days`
        } else if (diffDays < 365) {
            return `Selected: ${Math.round(diffMonths)} months`
        } else {
            return `Selected: ${Math.round(diffYears)} years`
        }
    }, [value])

    // Determines whether the current value is custom, or one of the pre-defined options
    const { isCustom, radioValue } = useMemo(() => {
        if (!value) return { isCustom: true }

        const index = ranges.findIndex(
            (val: SelectableDateRange) => val.start === value.start && val.end === value.end
        )

        if (index === -1) {
            return {
                radioValue: { label: 'Custom', start: value.start, end: value.end },
                isCustom: true,
            }
        } else {
            return { radioValue: ranges[index], isCustom: false }
        }
    }, [value, ranges])

    return (
        <div className="flex flex-col min-w-[140px] h-full">
            <RadioGroup
                value={radioValue}
                onChange={(radioValue: SelectableDateRange) =>
                    onChange({ start: radioValue.start, end: radioValue.end })
                }
            >
                {ranges.map((range) => (
                    <RadioGroup.Option value={range} key={range.label}>
                        {({ active, checked }) => (
                            <div
                                className={classNames(
                                    'my-1 hover:bg-gray-400 cursor-pointer',
                                    optionStyle,
                                    (active || checked) && 'bg-gray-400'
                                )}
                            >
                                {range.label}
                            </div>
                        )}
                    </RadioGroup.Option>
                ))}
            </RadioGroup>
            <div className="grow">
                <div
                    className={classNames(
                        optionStyle,
                        'mt-1 mb-8',
                        isCustom ? 'bg-gray-400' : 'text-gray-200'
                    )}
                >
                    Custom range
                </div>
            </div>
            <div className="text-gray-200 mb-2">{daysSelected}</div>
        </div>
    )
}
