import type * as PopperJs from '@popperjs/core'
import { PatternFormat, type NumberFormatValues } from 'react-number-format'
import type { Ref } from 'react'
import { useState, useCallback, forwardRef } from 'react'
import { Popover, Portal } from '@headlessui/react'
import { RiCalendarEventFill as CalendarIcon } from 'react-icons/ri'
import { Button, Input } from '../..'
import { DateTime } from 'luxon'
import classNames from 'classnames'
import { usePopper } from 'react-popper'
import { DatePickerCalendar } from './DatePickerCalendar'
import { MAX_SUPPORTED_DATE, MIN_SUPPORTED_DATE } from './utils'

const DEFAULT_INPUT_DATE_FORMAT = 'MM / dd / yyyy'

export interface DatePickerProps {
    name: string
    value: string | null
    onChange: (date: string | null) => void
    error?: string
    label?: string
    className?: String
    placeholder?: string
    minCalendarDate?: string
    maxCalendarDate?: string
    popperPlacement?: PopperJs.Placement
    popperStrategy?: PopperJs.PositioningStrategy
    dateFormat?: string
}

function toFormattedStr(date: string | null, dateFormat: string): string {
    if (!date) return ''
    return DateTime.fromISO(date).toFormat(dateFormat)
}

function getMaskArray(dateFormat: string): string[] {
    if (dateFormat === null) {
        return []
    }

    const matchResult = dateFormat.match(/[a-z]/gi)

    if (matchResult === null) {
        return []
    }

    return matchResult.map((char: string) => char.toUpperCase())
}

function getDateFormatPattern(dateFormat: string): string {
    const dateComponents = dateFormat.split('/')
    const pattern = dateComponents
        .map((component) => {
            if (component.toLowerCase().includes('d')) {
                return ' ## ' // Placeholder for day
            } else if (component.toLowerCase().includes('m')) {
                return ' ## ' // Placeholder for month
            } else if (component.toLowerCase().includes('y')) {
                return ' #### ' // Placeholder for year
            }
            return component // Keep non-date components unchanged
        })
        .join('/')
        .trim()

    return pattern
}

function DatePicker(
    {
        name,
        value,
        onChange,
        error,
        label,
        className,
        placeholder = 'MM / DD / YYYY',
        minCalendarDate = MIN_SUPPORTED_DATE.toISODate(),
        maxCalendarDate = MAX_SUPPORTED_DATE.toISODate(),
        popperPlacement = 'auto',
        popperStrategy = 'fixed',
        dateFormat = DEFAULT_INPUT_DATE_FORMAT,
    }: DatePickerProps,
    ref: Ref<HTMLInputElement>
): JSX.Element {
    // Positions the datepicker panel appropriately based on screen size and parent elements
    const [referenceElement, setReferenceElement] = useState<HTMLDivElement | null>()
    const [popperElement, setPopperElement] = useState<HTMLDivElement | null>()
    const { styles, attributes } = usePopper(referenceElement, popperElement, {
        placement: popperPlacement,
        strategy: popperStrategy,
        modifiers: [
            {
                name: 'offset',
                options: {
                    offset: [0, 8],
                },
            },
            {
                name: 'preventOverflow',
                options: {
                    altAxis: true,
                },
            },
        ],
    })

    const [calendarValue, setCalendarValue] = useState(value ?? '')

    // Only change input value when it is cleared or is a date value
    const handleInputValueChange = useCallback(
        (date: NumberFormatValues) => {
            if (!date.formattedValue) {
                setCalendarValue('')
                onChange(null)
            } else {
                const inputDate = DateTime.fromFormat(date.formattedValue, dateFormat)
                if (inputDate.isValid) {
                    setCalendarValue(inputDate.toISODate())
                    onChange(inputDate.toISODate())
                }
            }
        },
        [onChange, dateFormat]
    )

    return (
        <Popover className={classNames(className, 'relative')}>
            <div ref={setReferenceElement}>
                <PatternFormat
                    name={name}
                    customInput={Input} // passes all props below to <Input /> - https://github.com/s-yadav/react-number-format#custom-inputs
                    getInputRef={ref}
                    format={getDateFormatPattern(dateFormat)}
                    placeholder={placeholder}
                    mask={getMaskArray(dateFormat)}
                    value={toFormattedStr(value, dateFormat)}
                    error={error}
                    label={label}
                    onValueChange={handleInputValueChange}
                    fixedRightOverride={
                        <Popover.Button data-testid="datepicker-toggle-icon">
                            <CalendarIcon className="text-lg" />
                        </Popover.Button>
                    }
                />
            </div>

            <Portal>
                <Popover.Panel
                    className="border border-gray-500 rounded bg-gray-700 shadow-lg z-50"
                    ref={setPopperElement}
                    style={styles.popper}
                    data-testid="datepicker-panel"
                    {...attributes.popper}
                >
                    {({ close }) => (
                        <div
                            className={classNames('flex gap-6 p-4 rounded text-gray-25 text-base')}
                        >
                            <div className="flex flex-col">
                                {/* Calendar */}
                                <div className="grow mt-2">
                                    <DatePickerCalendar
                                        date={calendarValue}
                                        onChange={setCalendarValue}
                                        minDate={minCalendarDate}
                                        maxDate={maxCalendarDate}
                                        controlButtons={
                                            <div className="flex items-center justify-end">
                                                <Button
                                                    className="mr-4"
                                                    variant="secondary"
                                                    onClick={() => {
                                                        // reset to input value
                                                        setCalendarValue(value ?? '')
                                                        close()
                                                    }}
                                                >
                                                    Cancel
                                                </Button>
                                                <Button
                                                    disabled={!calendarValue}
                                                    onClick={() => {
                                                        onChange(
                                                            calendarValue ? calendarValue : null
                                                        ) // commit value change
                                                        close()
                                                    }}
                                                >
                                                    Apply
                                                </Button>
                                            </div>
                                        }
                                    />
                                </div>
                            </div>
                        </div>
                    )}
                </Popover.Panel>
            </Portal>
        </Popover>
    )
}

export default forwardRef<HTMLInputElement, DatePickerProps>(DatePicker)
