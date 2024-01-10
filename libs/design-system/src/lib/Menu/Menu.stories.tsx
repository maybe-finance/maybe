import type { Story, Meta } from '@storybook/react'
import {
    RiArrowDownSLine,
    RiCloseCircleLine,
    RiDeleteBinLine,
    RiInformationLine,
} from 'react-icons/ri'

import Menu from './Menu'

export default {
    title: 'Components/Menu',
    component: Menu,
    parameters: { controls: { exclude: ['className', 'as', 'refName'] } },
    argTypes: {
        variant: {
            control: 'select',
            options: ['primary', 'secondary'],
            description: 'Variant for Button component',
        },
    },
    args: {
        variant: 'primary',
    },
} as Meta

const Template: Story = (args) => (
    <div className="mb-32">
        <Menu>
            <Menu.Button variant={args.variant}>
                Click Me <RiArrowDownSLine />
            </Menu.Button>
            <Menu.Items>
                <Menu.Item icon={<RiInformationLine />}>Option 1</Menu.Item>
                <Menu.Item icon={<RiDeleteBinLine />} destructive={true}>
                    Option 2 (Destructive)
                </Menu.Item>
                <Menu.Item icon={<RiCloseCircleLine />} disabled={true}>
                    Option 3 (Disabled)
                </Menu.Item>
            </Menu.Items>
        </Menu>
    </div>
)

export const Base = Template.bind({})
