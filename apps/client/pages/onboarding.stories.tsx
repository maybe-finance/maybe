import type { Story, Meta } from '@storybook/react'
import OnboardingPage from './onboarding.tsx'
import React from 'react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AxiosProvider } from '@maybe-finance/client/shared'

const queryClient = new QueryClient()

export default {
    title: 'pages/onboarding.tsx',
    component: OnboardingPage,
    parameters: {
        nextjs: {
            appDirectory: false,
            router: {
                basePath: '/onboarding',
            },
        },
    },
    decorators: [
        (Story) => <QueryClientProvider client={queryClient}>{Story()}</QueryClientProvider>,
        (Story) => <AxiosProvider>{Story()}</AxiosProvider>,
    ],
} as Meta

const Template: Story = () => {
    return (
        <>
            <OnboardingPage />
        </>
    )
}

export const Base = Template.bind({})
