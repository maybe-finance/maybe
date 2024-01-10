import type { Story, Meta } from '@storybook/react'

import Popover from './Popover'

export default {
    title: 'Components/Popover',
    component: Popover,
    parameters: { controls: { exclude: ['className'] } },
} as Meta

const Template: Story = (args) => (
    <div className="mb-16">
        <Popover>
            <Popover.Button {...args}>Click Me</Popover.Button>
            <Popover.Panel>Panel Content</Popover.Panel>
        </Popover>
    </div>
)

export const Base = Template.bind({})
