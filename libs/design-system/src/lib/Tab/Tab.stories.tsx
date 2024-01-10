import type { Story, Meta } from '@storybook/react'
import { RiLineChartLine, RiBarChartFill, RiPieChartFill } from 'react-icons/ri'

import Tab from './Tab'

export default {
    title: 'Components/Tabs',
    argTypes: {},
    args: {},
} as Meta

export const Base: Story = (_args) => (
    <Tab.Group>
        <Tab.List>
            <Tab>Tab 1</Tab>
            <Tab>Tab 2</Tab>
            <Tab>Tab 3</Tab>
        </Tab.List>
    </Tab.Group>
)

export const WithIcons: Story = (_args) => (
    <Tab.Group>
        <Tab.List>
            <Tab icon={<RiLineChartLine />}>Line</Tab>
            <Tab icon={<RiBarChartFill />}>Bar</Tab>
            <Tab icon={<RiPieChartFill />}>Pie</Tab>
        </Tab.List>
    </Tab.Group>
)

export const WithPanels: Story = (_args) => (
    <Tab.Group>
        <Tab.List>
            <Tab>Tab 1</Tab>
            <Tab>Tab 2</Tab>
            <Tab>Tab 3</Tab>
        </Tab.List>
        <Tab.Panels>
            <Tab.Panel>Content 1</Tab.Panel>
            <Tab.Panel>Content 2</Tab.Panel>
            <Tab.Panel>Content 3</Tab.Panel>
        </Tab.Panels>
    </Tab.Group>
)
