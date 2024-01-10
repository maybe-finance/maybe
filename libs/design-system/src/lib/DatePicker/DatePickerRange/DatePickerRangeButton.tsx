import type { DateRange } from '../selectableRanges'
import { Popover } from '@headlessui/react'
import { DateTime } from 'luxon'
import { RiCalendarEventFill } from 'react-icons/ri'

export interface DatePickerRangeButtonProps {
    value?: Partial<DateRange>
    setPopperReferenceElement: (el: HTMLButtonElement) => void
}

// The datepicker button that toggles the panel to open/close, and displays the currently selected date range
export function DatePickerRangeButton({
    value,
    setPopperReferenceElement,
}: DatePickerRangeButtonProps) {
    return (
        <Popover.Button ref={setPopperReferenceElement} data-testid="datepicker-range-toggle-icon">
            {({ open }) => {
                return (
                    <div
                        className="flex items-center justify-between font-normal text-gray-25 text-base border border-gray-200 rounded py-2 px-4"
                        data-testid="date-range"
                    >
                        {open || !value ? (
                            <span>Select a date range</span>
                        ) : (
                            <>
                                {value.start && (
                                    <span>
                                        {DateTime.fromISO(value.start).toFormat('MMM dd, yyyy')}
                                    </span>
                                )}
                                <span className="mx-2 text-gray-200">to</span>
                                {value.end && (
                                    <span>
                                        {DateTime.fromISO(value.end).toFormat('MMM dd, yyyy')}
                                    </span>
                                )}
                            </>
                        )}
                        <RiCalendarEventFill className="ml-4 text-lg" />
                    </div>
                )
            }}
        </Popover.Button>
    )
}
