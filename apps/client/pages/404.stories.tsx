import React from 'react'
import type { Story, Meta } from '@storybook/react'
import Page404 from './404'

export default {
    title: 'pages/Page404',
    component: Page404,
} as Meta

export const Default: Story = () => <Page404 />;
