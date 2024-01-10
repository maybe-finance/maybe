import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { act } from 'react-dom/test-utils'
import { InputPassword } from '..'

describe('InputPassword', () => {
    describe('when rendered', () => {
        it('should render plainly when reveal button and complexity bar are disabled', () => {
            const component = render(
                <InputPassword showRevealButton={false} showComplexityBar={false} />
            )

            expect(component.queryByTestId('reveal-password-button')).not.toBeInTheDocument()
            expect(component.queryByTitle('Password is very weak')).not.toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
        it('should render the reveal button when enabled', async () => {
            let component
            await act(async () => {
                component = render(<InputPassword showRevealButton={true} data-testid="input" />)
            })

            expect(screen.getByTestId('reveal-password-button')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
        it('should render the complexity bar when enabled', async () => {
            let component
            await act(async () => {
                component = render(<InputPassword showComplexityBar={true} />)
            })

            expect(screen.getByTitle('Password is very weak')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
        it('should render a complexity based on the calculated score', async () => {
            let component
            await act(async () => {
                component = render(
                    <InputPassword
                        showComplexityBar={true}
                        value="Hello, World!"
                        onChange={() => null}
                        passwordComplexity={() => 3}
                    />
                )
            })

            expect(screen.getByTitle('Password is strong')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
        it('should show password requirements on `onFocus`', async () => {
            let component
            await act(async () => {
                component = render(
                    <InputPassword placeholder="Password" showPasswordRequirements={true} />
                )
            })

            const inputElement = screen.getByPlaceholderText('Password')

            inputElement.focus()
            await waitFor(() => {
                expect(screen.getByText('Password requirements')).toBeVisible()
            })

            expect(component).toMatchSnapshot()
        })
        it('should show tooltip on reveal button hover', async () => {
            let component
            await act(async () => {
                component = render(<InputPassword showRevealButton={true} />)
            })

            userEvent.hover(screen.getByTestId('reveal-password-button'))
            await waitFor(() => {
                expect(screen.getByText(/^show password$/i)).toBeVisible()
            })

            expect(component).toMatchSnapshot()
        })
    })
})
