import type * as PopperJs from '@popperjs/core'
import type { DateRange, SelectableDateRange, SelectableRangeKeys } from '../selectableRanges'

import { Popover, Portal } from '@headlessui/react'
import classNames from 'classnames'
import { DateTime } from 'luxon'
import { RiArrowRightLine } from 'react-icons/ri'
import { useEffect, useMemo, useState } from 'react'
import { usePopper } from 'react-popper'
import { Button } from '../../Button'
import { DatePickerRangeCalendar } from './DatePickerRangeCalendar'
import { DatePickerInput } from '../DatePickerInput'
import { getNormalizedRanges } from '../selectableRanges'
import { DatePickerQuickSelect } from '../DatePickerQuickSelect'
import { DatePickerRangeButton } from './DatePickerRangeButton'
import { DatePickerRangeTabs } from './DatePickerRangeTabs'

export interface DatePickerRangeProps {
    variant?: 'default' | 'tabs' | 'tabs-custom'
    value?: Partial<DateRange>
    selectableRanges: Array<SelectableRangeKeys | SelectableDateRange>
    onChange: (range: DateRange) => void
    className?: string
    minDate?: string
    maxDate?: string
    popperPlacement?: PopperJs.Placement
    popperStrategy?: PopperJs.PositioningStrategy
}

export function DatePickerRange({
    variant = 'default',
    value,
    selectableRanges,
    onChange,
    className,
    minDate = DateTime.now().minus({ years: 50 }).toISODate(),
    maxDate = DateTime.now().toISODate(),
    popperPlacement = 'bottom-end',
    popperStrategy = 'fixed',
}: DatePickerRangeProps) {
    // PopperJS configuration: positions the datepicker panel appropriately based on screen size and parent elements
    const [referenceElement, setReferenceElement] = useState<HTMLElement | null>()
    const [popperElement, setPopperElement] = useState<HTMLDivElement | null>()
    const { styles, attributes } = usePopper(referenceElement, popperElement, {
        placement: popperPlacement,
        strategy: popperStrategy,
        modifiers: [
            {
                name: 'offset',
                options: {
                    offset: [0, variant === 'default' ? 8 : 16],
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

    const [range, setRange] = useState(value)
    const [rangeError, setRangeError] = useState(false)
    const [startError, setStartError] = useState(false)
    const [endError, setEndError] = useState(false)

    useEffect(() => {
        setRangeError(
            range && !!range.start && !!range.end
                ? DateTime.fromISO(range.start) > DateTime.fromISO(range.end)
                : false
        )
    }, [range])

    const tabs = useMemo<SelectableDateRange[]>(() => {
        return getNormalizedRanges(selectableRanges)
    }, [selectableRanges])

    return (
        <Popover className={classNames(className, 'relative z-10')}>
            {variant === 'tabs' ? (
                <DatePickerRangeTabs
                    variant="default"
                    tabs={tabs}
                    value={value}
                    onChange={(range) => {
                        onChange(range)
                        setRange(range)
                    }}
                />
            ) : variant === 'tabs-custom' ? (
                <DatePickerRangeTabs
                    variant="custom"
                    tabs={[...tabs, 'custom']}
                    value={value}
                    onChange={(range) => {
                        onChange(range)
                        setRange(range)
                    }}
                    setReferenceElement={setReferenceElement}
                />
            ) : (
                <DatePickerRangeButton
                    value={value}
                    setPopperReferenceElement={setReferenceElement}
                />
            )}

            <Portal>
                <Popover.Panel
                    className={classNames(
                        'border border-gray-500 rounded bg-gray-700 shadow-lg z-50'
                    )}
                    ref={setPopperElement}
                    style={styles.popper}
                    data-testid="datepicker-range-panel"
                    {...attributes.popper}
                >
                    {({ close }) => (
                        <div
                            className={classNames('flex gap-6 p-4 rounded text-gray-25 text-base')}
                        >
                            {variant === 'default' && (
                                <div className="hidden sm:block whitespace-nowrap">
                                    <DatePickerQuickSelect
                                        ranges={tabs}
                                        value={range}
                                        onChange={setRange}
                                    />
                                </div>
                            )}
                            <div className="flex flex-col">
                                <div className="grow">
                                    <DatePickerRangeCalendar
                                        range={range}
                                        onChange={setRange}
                                        minDate={minDate}
                                        maxDate={maxDate}
                                        rangeInputs={
                                            <div className="flex flex-col xs:flex-row justify-between gap-2 h-18 my-2">
                                                <DatePickerInput
                                                    value={range ? range.start : undefined}
                                                    onChange={(start: string) =>
                                                        setRange((previous) => ({
                                                            ...previous,
                                                            start,
                                                        }))
                                                    }
                                                    hasError={startError || rangeError}
                                                    onError={(err) => setStartError(!!err)}
                                                    minDate={minDate}
                                                    maxDate={maxDate}
                                                    className="w-full xs:w-36"
                                                />
                                                <span className="flex justify-center items-center text-gray-50">
                                                    <RiArrowRightLine size={20} />
                                                </span>
                                                <DatePickerInput
                                                    value={range ? range.end : undefined}
                                                    onChange={(end: string) =>
                                                        setRange((previous) => ({
                                                            ...previous,
                                                            end,
                                                        }))
                                                    }
                                                    hasError={endError || rangeError}
                                                    onError={(err) => setEndError(!!err)}
                                                    minDate={minDate}
                                                    maxDate={maxDate}
                                                    className="w-full mb-4 xs:mb-0 xs:w-36" // On mobile, calendar sits under the inputs
                                                />
                                            </div>
                                        }
                                        controlButtons={
                                            <div className="flex items-center justify-end">
                                                <Button
                                                    className="mr-4"
                                                    variant="secondary"
                                                    onClick={() => close()}
                                                >
                                                    Cancel
                                                </Button>
                                                <Button
                                                    onClick={() => {
                                                        onChange({
                                                            start: range!.start!,
                                                            end: range!.end!,
                                                        })
                                                        close()
                                                    }}
                                                    disabled={
                                                        rangeError ||
                                                        startError ||
                                                        endError ||
                                                        !range ||
                                                        !range.start ||
                                                        !range.end
                                                    }
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
