import type { Story, Meta } from '@storybook/react'
import type { InputProps } from '..'

import { Input } from '..'
import { FormGroup } from '../../FormGroup'
import { RiTerminalBoxFill, RiWifiFill } from 'react-icons/ri'

export default {
    title: 'Components/Inputs/Input',
    component: Input,
    parameters: {
        controls: { exclude: ['variant', 'className', 'labelClassName'] },
    },
    argTypes: {
        type: {
            control: {
                type: 'select',
                options: ['text', 'number', 'password', 'email'],
            },
        },
        colorHint: {
            control: {
                type: 'text',
                description: 'Color to display on the right side of the input',
            },
        },
        fixedLeftOverride: {
            control: {
                type: 'text',
                description: 'Override content placed on the left side of the input',
            },
        },
        fixedRightOverride: {
            control: {
                type: 'text',
                description: 'Override content placed on the right side of the input',
            },
        },
        disabled: {
            control: {
                type: 'boolean',
            },
        },
        readOnly: {
            control: {
                type: 'boolean',
            },
        },
        hint: {
            control: {
                type: 'text',
            },
        },
        error: {
            control: {
                type: 'text',
            },
        },
    },
    args: {
        label: 'Label',
        placeholder: 'Placeholder',
        type: 'text',
    },
} as Meta

const Template: Story<InputProps> = (args) => (
    <FormGroup className="w-60">
        <Input {...args} />
    </FormGroup>
)

export const Base = Template.bind({})

export const WithColorHint = Template.bind({})
WithColorHint.args = { colorHint: 'cyan' }

export const WithIcons = Template.bind({})
WithIcons.args = {
    fixedLeftOverride: <RiTerminalBoxFill className="text-lg" />,
    fixedRightOverride: <RiWifiFill className="text-lg" />,
}
