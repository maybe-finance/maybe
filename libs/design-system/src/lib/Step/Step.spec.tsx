import { fireEvent, render, screen } from '@testing-library/react'
import { useState } from 'react'
import { Step } from '.'

describe('Steps', () => {
    describe('when linear', () => {
        it('should render correctly', () => {
            const component = render(
                <Step.Group currentStep={0}>
                    <Step.List>
                        <Step>Step 1</Step>
                        <Step>Step 2</Step>
                    </Step.List>
                    <Step.Panels>
                        <Step.Panel>Content 1</Step.Panel>
                        <Step.Panel>Content 2</Step.Panel>
                    </Step.Panels>
                </Step.Group>
            )

            expect(screen.getByText('Step 1')).toBeInTheDocument()
            expect(screen.queryByText('Content 1')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })

        it('should not allow navigation', () => {
            render(
                <Step.Group currentStep={0}>
                    <Step.List>
                        <Step>Step 1</Step>
                        <Step>Step 2</Step>
                    </Step.List>
                    <Step.Panels>
                        <Step.Panel>Content 1</Step.Panel>
                        <Step.Panel>Content 2</Step.Panel>
                    </Step.Panels>
                </Step.Group>
            )

            // Content 1 visible, Content 2 hidden
            expect(screen.getByText('Content 1')).toBeInTheDocument()
            expect(screen.queryByText('Content 2')).not.toBeInTheDocument()

            fireEvent.click(screen.getByText('Step 2'))

            // Content 1 visible, content 2 hidden
            expect(screen.getByText('Content 1')).toBeInTheDocument()
            expect(screen.queryByText('Content 2')).not.toBeInTheDocument()
        })
    })

    describe('when non-linear', () => {
        it('should render correctly when non-linear', () => {
            const component = render(
                <Step.Group linear={false} currentStep={0}>
                    <Step.List>
                        <Step>Step 1</Step>
                        <Step>Step 2</Step>
                    </Step.List>
                    <Step.Panels>
                        <Step.Panel>Content 1</Step.Panel>
                        <Step.Panel>Content 2</Step.Panel>
                    </Step.Panels>
                </Step.Group>
            )

            expect(screen.getByText('Step 1')).toBeInTheDocument()
            expect(screen.queryByText('Content 1')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })

        it('should allow navigation', () => {
            const Component = () => {
                const [currentStep, setCurrentStep] = useState(0)
                return (
                    <Step.Group linear={false} currentStep={currentStep} onChange={setCurrentStep}>
                        <Step.List>
                            <Step>Step 1</Step>
                            <Step>Step 2</Step>
                        </Step.List>
                        <Step.Panels>
                            <Step.Panel>Content 1</Step.Panel>
                            <Step.Panel>Content 2</Step.Panel>
                        </Step.Panels>
                    </Step.Group>
                )
            }

            render(<Component />)

            // Content 1 visible, Content 2 hidden
            expect(screen.getByText('Content 1')).toBeInTheDocument()
            expect(screen.queryByText('Content 2')).not.toBeInTheDocument()

            fireEvent.click(screen.getByText('Step 2'))

            // Content 2 visible, content 1 hidden
            expect(screen.getByText('Content 2')).toBeInTheDocument()
            expect(screen.queryByText('Content 1')).not.toBeInTheDocument()
        })
    })
})
