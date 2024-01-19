import type { Story, Meta } from '@storybook/react'
import Maintenance from './Maintenance'

export default {
    title: 'components/Maintenance.tsx',
    component: Maintenance,
} as Meta

const Template: Story = (args) => <Maintenance />

export const Base = Template.bind({})
