import type { Story, Meta } from '@storybook/react'
import Maintenance from './Maintenance.tsx'
import React from 'react'

export default {
    title: 'components/Maintenance.tsx',
    component: Maintenance,
} as Meta

const Template: Story = () => {
    return (
        <>
            <Maintenance />
        </>
    )
}

export const Base = Template.bind({})
