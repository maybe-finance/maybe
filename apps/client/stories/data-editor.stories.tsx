import React from 'react'
import type { Story, Meta } from '@storybook/react'
import DataEditor from '../pages/data-editor'

export default {
    title: 'pages/DataEditor',
    component: DataEditor,
} as Meta

export const Default: Story = () => <DataEditor />
