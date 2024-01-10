import type { Story, Meta } from '@storybook/react'
import type { ToastProps } from './Toast'

import Toast from './Toast'

export default {
    title: 'Components/Toast',
    component: Toast,
    parameters: { controls: { exclude: ['className', 'onClick'] } },
    argTypes: {
        children: {
            control: 'text',
            description: 'Toast content',
        },
        variant: {
            control: { type: 'select' },
            description: 'Toast variant',
        },
    },
    args: {
        children: 'Toast message',
    },
} as Meta

const Template: Story<ToastProps> = (args) => <Toast {...args} />

export const Base = Template.bind({})

export const Info = Template.bind({})
Info.args = { variant: 'info' }

export const Success = Template.bind({})
Success.args = { variant: 'success' }

export const Error = Template.bind({})
Error.args = { variant: 'error' }
