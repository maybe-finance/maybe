import type { Story, Meta } from '@storybook/react'

import LoadingPlaceholder from './LoadingPlaceholder'

export default {
    title: 'Components/LoadingPlaceholder',
    component: LoadingPlaceholder,
    parameters: { controls: { exclude: ['className', 'overlayClassName'] } },
} as Meta

export const Base: Story = (args) => <LoadingPlaceholder {...args}>Content</LoadingPlaceholder>
