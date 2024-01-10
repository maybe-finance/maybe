import type { Story, Meta } from '@storybook/react'
import { useState } from 'react'
import Listbox from './Listbox'
import { RiLineChartLine } from 'react-icons/ri'

export default {
    title: 'Components/Listbox',
    component: Listbox,
    parameters: { controls: { exclude: ['className', 'as', 'refName'] } },
    argTypes: {
        icon: {
            control: 'boolean',
        },
        iconPosition: {
            control: 'select',
            options: ['left', 'right'],
            description: 'Side of the icon',
            label: 'Icon Position',
        },
        checkIconPosition: {
            control: 'select',
            options: ['left', 'right'],
            description: 'Side of the selected check',
        },
    },
    args: {
        icon: true,
        iconPosition: 'left',
        checkIconPosition: 'right',
        label: 'Listbox',
    },
} as Meta

const Template: Story = ({ label, icon, iconPosition, checkIconPosition }) => {
    const [value, setValue] = useState('Option 1')

    return (
        <div className="w-32 mb-32">
            <Listbox value={value} onChange={setValue}>
                <Listbox.Button label={label}>{value}</Listbox.Button>
                <Listbox.Options>
                    <Listbox.Option
                        value="Option 1"
                        icon={icon && RiLineChartLine}
                        iconPosition={iconPosition}
                        checkIconPosition={checkIconPosition}
                    >
                        Option 1
                    </Listbox.Option>
                    <Listbox.Option
                        value="Option 2"
                        icon={icon && RiLineChartLine}
                        iconPosition={iconPosition}
                        checkIconPosition={checkIconPosition}
                    >
                        Option 2
                    </Listbox.Option>
                    <Listbox.Option
                        value="Option 3"
                        icon={icon && RiLineChartLine}
                        iconPosition={iconPosition}
                        checkIconPosition={checkIconPosition}
                    >
                        Option 3
                    </Listbox.Option>
                    <Listbox.Option value="Option 6" disabled={true}>
                        Disabled
                    </Listbox.Option>
                </Listbox.Options>
            </Listbox>
        </div>
    )
}

export const Base = Template.bind({})
