import { fireEvent, render, screen } from '@testing-library/react'
import { Popover } from './'

// Not tested too thoroughly, most logic is covered by Headless UI base
describe('Popover', () => {
    describe('when closed', () => {
        it('should render the button', () => {
            const component = render(
                <Popover>
                    <Popover.Button>Click Me</Popover.Button>
                    <Popover.Panel>Content</Popover.Panel>
                </Popover>
            )

            expect(screen.getByText('Click Me')).toBeVisible()
            expect(screen.queryByText('Content')).not.toBeVisible()
            expect(component).toMatchSnapshot()
        })
    })

    describe('when opened', () => {
        it('should render the button and the panel', () => {
            const component = render(
                <Popover>
                    <Popover.Button>Click Me</Popover.Button>
                    <Popover.Panel>Content</Popover.Panel>
                </Popover>
            )

            fireEvent.click(screen.getByText('Click Me'))
            expect(screen.getByText('Click Me')).toBeVisible()
            expect(screen.getByText('Content')).toBeVisible()
            expect(component).toMatchSnapshot()
        })
    })
})
