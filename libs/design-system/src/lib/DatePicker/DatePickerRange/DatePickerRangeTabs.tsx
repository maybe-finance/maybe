import type { Dispatch, SetStateAction } from 'react'
import type { DateRange, SelectableDateRange } from '..'
import { useMemo } from 'react'
import { Popover, Tab } from '@headlessui/react'
import classNames from 'classnames'
import { RiCalendarEventFill } from 'react-icons/ri'

export type DatePickerRangeTabsProps =
    | {
          variant: 'custom'
          value?: Partial<DateRange>
          onChange: (range: DateRange) => void
          tabs: Array<SelectableDateRange | 'custom'>
          setReferenceElement?: Dispatch<SetStateAction<HTMLElement | null | undefined>>
      }
    | {
          variant: 'default'
          value?: Partial<DateRange>
          onChange: (range: DateRange) => void
          tabs: SelectableDateRange[]
          setReferenceElement?: never
      }

function DefaultTab({ value, selected }: { value: string; selected: boolean }) {
    return (
        <span
            className={classNames(
                'flex items-center px-4 py-1 text-base rounded hover:bg-gray-300',
                selected ? 'bg-gray-400 text-white shadow' : 'text-gray-100'
            )}
        >
            {value}
        </span>
    )
}

const NOT_SELECTED_TAB_INDEX = 999

// The tabs that persistently show and can toggle the panel to open/close
export function DatePickerRangeTabs(props: DatePickerRangeTabsProps) {
    const selectedIndex = useMemo(() => {
        // No range, no tab selected
        if (!props.value?.start || !props.value?.end) {
            return NOT_SELECTED_TAB_INDEX
        }

        const tabIndex = props.tabs.findIndex(
            (tab) =>
                typeof tab !== 'string' && // not custom tab
                tab.start === props.value?.start &&
                tab.end === props.value?.end
        )

        // known range, select tab
        if (tabIndex !== -1) {
            return tabIndex
        }

        const customTabIndex = props.tabs.findIndex(
            (tab) => typeof tab === 'string' && tab === 'custom'
        )

        // custom range, select custom tab
        if (customTabIndex !== -1) {
            return customTabIndex
        }

        return NOT_SELECTED_TAB_INDEX
    }, [props.tabs, props.value?.start, props.value?.end])

    // Render the custom variant (a datepicker shows up as the very last tab)
    if (props.variant === 'custom') {
        return (
            <div className="flex items-center">
                <Tab.Group
                    selectedIndex={selectedIndex}
                    onChange={(index: number) => {
                        const tab = props.tabs[index]

                        // If the "custom" tab is clicked, we defer state updates until the user interacts with the calendar panel and submits
                        if (tab !== 'custom') {
                            props.onChange({ start: tab.start, end: tab.end })
                        }
                    }}
                >
                    <Tab.List className="inline-flex items-center p-1 gap-x-2 text-white">
                        {props.tabs.map((tab) => (
                            <Tab key={typeof tab === 'string' ? tab : tab.label}>
                                {({ selected }) =>
                                    tab === 'custom' ? (
                                        <Popover.Button
                                            ref={props.setReferenceElement}
                                            as="div" // Cannot render a button inside of a button (<Tab> renders as a button by default)
                                            data-testid="datepicker-range-toggle-icon-tabs"
                                            className={classNames(
                                                'px-4 flex items-center text-gray-100 rounded h-8 hover:bg-gray-300',
                                                selected && 'bg-gray-400 text-white shadow'
                                            )}
                                        >
                                            <RiCalendarEventFill
                                                className={classNames(
                                                    'text-lg cursor-pointer',
                                                    selected && 'text-white'
                                                )}
                                            />
                                        </Popover.Button>
                                    ) : (
                                        <DefaultTab value={tab.labelShort} selected={selected} />
                                    )
                                }
                            </Tab>
                        ))}
                    </Tab.List>
                </Tab.Group>
            </div>
        )
    }

    // Default implementation - no datepicker is available to click here
    return (
        <div className="flex items-center">
            <Tab.Group
                selectedIndex={selectedIndex}
                onChange={(index: number) => {
                    const { start, end } = props.tabs[index]
                    props.onChange({ start, end })
                }}
            >
                <Tab.List className="inline-flex items-center p-1 text-white">
                    {props.tabs.map((tab) => (
                        <Tab key={tab.labelShort}>
                            {({ selected }) => (
                                <DefaultTab value={tab.labelShort} selected={selected} />
                            )}
                        </Tab>
                    ))}
                </Tab.List>
            </Tab.Group>
        </div>
    )
}
