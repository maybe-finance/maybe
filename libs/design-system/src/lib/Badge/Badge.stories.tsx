import type { Story, Meta } from '@storybook/react'
import type { BadgeProps } from './Badge'

import Badge from './Badge'

export default {
    title: 'Components/Badge',
    component: Badge,
    parameters: { controls: { exclude: ['as', 'className'] } },
    argTypes: {
        children: {
            control: 'text',
            description: 'Badge content',
        },
    },
    args: {
        children: '+4.5M',
        variant: 'teal',
    },
} as Meta

const Template: Story<BadgeProps> = (args) => <Badge {...args} />

export const Base = Template.bind({})

export const Highlighted = Template.bind({})
Highlighted.args = { highlighted: true }
