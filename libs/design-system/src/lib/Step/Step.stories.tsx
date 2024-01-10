import type { Story, Meta } from '@storybook/react'
import { useState } from 'react'
import { Button } from '../Button'

import Step from './Step'

export default {
    title: 'Components/Steps',
} as Meta

export const Base: Story = () => {
    const [currentStep, setCurrentStep] = useState(0)

    return (
        <>
            <Step.Group currentStep={currentStep}>
                <Step.List>
                    <Step>Step 1</Step>
                    <Step>Step 2</Step>
                    <Step>Step 3</Step>
                </Step.List>
                <Step.Panels className="my-4 text-white">
                    <Step.Panel>Step 1 Content</Step.Panel>
                    <Step.Panel>Step 2 Content</Step.Panel>
                    <Step.Panel>Step 3 Content</Step.Panel>
                </Step.Panels>
            </Step.Group>
            <div className="space-x-3">
                <Button
                    variant="secondary"
                    disabled={currentStep <= 0}
                    onClick={() => setCurrentStep((currentStep) => currentStep - 1)}
                >
                    Back
                </Button>
                <Button
                    disabled={currentStep >= 2}
                    onClick={() => setCurrentStep((currentStep) => currentStep + 1)}
                >
                    Next
                </Button>
            </div>
        </>
    )
}

export const NonLinear: Story = () => {
    const [currentStep, setCurrentStep] = useState(0)

    return (
        <Step.Group linear={false} currentStep={currentStep} onChange={setCurrentStep}>
            <Step.List>
                <Step>Step 1</Step>
                <Step>Step 2</Step>
                <Step>Step 3</Step>
            </Step.List>
            <Step.Panels className="my-4 text-white">
                <Step.Panel>Step 1 Content</Step.Panel>
                <Step.Panel>Step 2 Content</Step.Panel>
                <Step.Panel>Step 3 Content</Step.Panel>
            </Step.Panels>
        </Step.Group>
    )
}

export const StepStatuses: Story = () => {
    return (
        <Step.Group currentStep={2}>
            <Step.List>
                <Step status="complete">Step 1</Step>
                <Step status="error">Step 2</Step>
                <Step status="incomplete">Step 3</Step>
                <Step status="incomplete">Step 4</Step>
            </Step.List>
            <Step.Panels className="my-4 text-white">
                <Step.Panel>Step 1 Content</Step.Panel>
                <Step.Panel>Step 2 Content</Step.Panel>
                <Step.Panel>Step 3 Content</Step.Panel>
            </Step.Panels>
        </Step.Group>
    )
}
