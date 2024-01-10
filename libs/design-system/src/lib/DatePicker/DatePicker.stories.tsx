import type { Story, Meta } from '@storybook/react'
import type { DatePickerProps } from './DatePicker'
import { useState } from 'react'

import DatePicker from './DatePicker'

export default {
    title: 'Components/DatePicker',
    component: DatePicker,
    argTypes: {
        placeholder: { description: 'The Input placeholder value' },
        value: { description: 'Valid ISO 8601 string' },
        minDate: { control: 'text', description: 'Valid ISO 8601 string' },
        maxDate: { control: 'text', description: 'Valid ISO 8601 string' },
        error: { control: 'text', description: 'Error message' },
    },
} as Meta

export const Base: Story<DatePickerProps> = (props: DatePickerProps) => {
    const [date, setDate] = useState<Date | null>(null)

    return (
        <div className="h-96 flex justify-center">
            <DatePicker {...props} value={date} onChange={setDate} label="Sample label" />
        </div>
    )
}
