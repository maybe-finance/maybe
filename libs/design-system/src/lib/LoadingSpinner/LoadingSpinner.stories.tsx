import type { Story, Meta } from '@storybook/react'

import LoadingSpinner from './LoadingSpinner'

export default {
    title: 'Components/LoadingSpinner',
    component: LoadingSpinner,
} as Meta

export const Base: Story = () => <LoadingSpinner />
