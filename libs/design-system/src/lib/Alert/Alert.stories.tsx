import type { Meta, Story } from '@storybook/react'
import type { AlertProps } from './Alert'
import { RiMailCheckLine as CustomIcon } from 'react-icons/ri'

import Alert from './Alert'

export default {
    title: 'Components/Alert',
    component: Alert,
    parameters: { controls: { exclude: ['onClose'] } },
    argTypes: {
        variant: {
            control: { type: 'select' },
        },
        icon: {
            table: {
                disable: true,
            },
        },
    },
    args: {
        children: 'Alert message!',
        isVisible: true,
    },
} as Meta

const Template: Story<AlertProps> = (args) => {
    return <Alert {...args} />
}

export const Base = Template.bind({})

export const Info = Template.bind({})
Info.args = { variant: 'info' }

export const Error = Template.bind({})
Error.args = { variant: 'error' }

export const Success = Template.bind({})
Success.args = { variant: 'success' }

export const WithCloseButton = Template.bind({})
WithCloseButton.args = {
    onClose: () => alert('onClose()'),
    children:
        'Lorem ipsum, dolor sit amet consectetur adipisicing elit. Soluta sequi ipsam eligendi a cumque corrupti eum obcaecati perspiciatis. Nobis in ab illo et sequi explicabo quisquam dolor corrupti totam architecto.',
}

export const WithCustomIcon = Template.bind({})
WithCustomIcon.args = {
    children: 'I have a custom icon',
    icon: CustomIcon,
}
