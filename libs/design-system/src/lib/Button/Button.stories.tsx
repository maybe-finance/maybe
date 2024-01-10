import type { Story, Meta } from '@storybook/react'
import type { ButtonProps } from './Button'

import Button from './Button'

export default {
    title: 'Components/Button',
    component: Button,
    parameters: { controls: { exclude: ['as', 'className', 'onClick'] } },
    argTypes: {
        children: {
            control: 'text',
            description: 'Button content',
        },
    },
    args: {
        children: 'Click Me!',
        variant: 'primary',
    },
} as Meta

const Template: Story<ButtonProps> = (args) => <Button {...args} />

export const Base = Template.bind({})
