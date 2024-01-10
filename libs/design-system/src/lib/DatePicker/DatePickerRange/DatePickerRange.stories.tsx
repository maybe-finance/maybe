import type { Story, Meta } from '@storybook/react'
import type { DateRange } from '../selectableRanges'
import { useState } from 'react'
import { DateTime } from 'luxon'
import { DatePickerRange } from './DatePickerRange'

export default {
    title: 'Components/DatePicker/DatePickerRange',
    component: DatePickerRange,
    argTypes: {
        placeholder: { description: 'The Input placeholder value' },
        value: { description: 'Valid ISO 8601 string' },
        minDate: { control: 'text', description: 'Valid ISO 8601 string' },
        maxDate: { control: 'text', description: 'Valid ISO 8601 string' },
    },
} as Meta

export const Base: Story = (args) => {
    const [range, setRange] = useState<Partial<DateRange> | undefined>(undefined)

    return (
        <div className="flex justify-center h-[600px]">
            <DatePickerRange
                {...args}
                value={range}
                selectableRanges={[
                    'this-month',
                    'prior-month',
                    'this-year',
                    'prior-year',
                    {
                        label: 'All time',
                        labelShort: 'All',
                        start: DateTime.now().minus({ years: 3 }).toISODate(), // this would be dynamic in real app
                        end: DateTime.now().toISODate(),
                    },
                ]}
                onChange={setRange}
            />
        </div>
    )
}

export const Tabs: Story = (args) => {
    // const [range, setRange] = useState<Partial<DateRange> | undefined>(undefined)

    const [range, setRange] = useState<Partial<DateRange> | undefined>({
        start: '2022-02-01',
        end: '2022-02-28',
    })

    return (
        <div className="flex justify-center h-[600px]">
            <DatePickerRange
                {...args}
                variant="tabs"
                value={range}
                selectableRanges={[
                    'day',
                    'last-7-days',
                    'last-30-days',
                    'last-90-days',
                    {
                        label: 'All time',
                        labelShort: 'All',
                        start: DateTime.now().minus({ years: 3 }).toISODate(), // this would be dynamic in real app
                        end: DateTime.now().toISODate(),
                    },
                ]}
                onChange={setRange}
                popperPlacement="bottom-end"
            />
        </div>
    )
}

export const TabsWithCustomRange: Story = (args) => {
    // const [range, setRange] = useState<Partial<DateRange> | undefined>(undefined)

    const [range, setRange] = useState<Partial<DateRange> | undefined>({
        start: '2022-02-01',
        end: '2022-02-28',
    })

    return (
        <div className="flex justify-center h-[600px]">
            <DatePickerRange
                {...args}
                variant="tabs-custom"
                value={range}
                selectableRanges={[
                    'day',
                    'last-7-days',
                    'last-30-days',
                    'last-90-days',
                    {
                        label: 'All time',
                        labelShort: 'All',
                        start: DateTime.now().minus({ years: 3 }).toISODate(), // this would be dynamic in real app
                        end: DateTime.now().toISODate(),
                    },
                ]}
                onChange={setRange}
                popperPlacement="bottom-end"
            />
        </div>
    )
}
