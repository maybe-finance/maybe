import type { Story, Meta } from '@storybook/react'

import FractionalCircle from './FractionalCircle'

export default {
    title: 'Components/FractionalCircle',
    component: FractionalCircle,
    argTypes: {
        variant: {
            options: ['default'],
            control: { type: 'radio' },
            defaultValue: 'default',
        },
    },
    args: {
        radius: 50,
        stroke: 10,
        percent: 15,
    },
} as Meta

export const Base: Story = (args) => (
    <div className="flex items-center justify-center">
        <FractionalCircle {...(args as any)} />
    </div>
)
