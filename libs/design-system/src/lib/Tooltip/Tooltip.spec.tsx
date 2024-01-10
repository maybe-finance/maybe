import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { act } from 'react-dom/test-utils'
import { Tooltip } from '.'

describe('Tooltip', () => {
    describe('when rendered', () => {
        it('should show tooltip content on tooltip trigger `focus`', async () => {
            let component
            await act(async () => {
                component = render(
                    <Tooltip content="Tooltip Content">
                        <button data-testid="tooltip-trigger">Tooltip trigger</button>
                    </Tooltip>
                )
            })

            const tooltipTrrigger = screen.getByTestId('tooltip-trigger')

            tooltipTrrigger.focus()
            await waitFor(() => {
                expect(screen.getByText(/^tooltip content$/i)).toBeVisible()
            })

            expect(component).toMatchSnapshot()
        })
        it('should show tooltip on tooltip trigger `hover`', async () => {
            let component
            await act(async () => {
                component = render(
                    <Tooltip content="Tooltip Content">
                        <button data-testid="tooltip-trigger">Tooltip trigger</button>
                    </Tooltip>
                )
            })

            const tooltipTrrigger = screen.getByTestId('tooltip-trigger')

            userEvent.hover(tooltipTrrigger)
            await waitFor(() => {
                expect(screen.getByText(/^tooltip content$/i)).toBeVisible()
            })

            expect(component).toMatchSnapshot()
        })
    })
})
