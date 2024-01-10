import { fireEvent, render, screen } from '@testing-library/react'
import { AccordionRow } from './'

describe('AccordionRow', () => {
    describe('when rendered with text content', () => {
        it('should display the text', () => {
            const component = render(<AccordionRow label="Label">Hello, World!</AccordionRow>)

            expect(screen.getByText('Label')).toBeInTheDocument()
            expect(screen.getByText('Hello, World!')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })

    describe('when passed an `href` prop', () => {
        it('should render as a link', () => {
            const component = render(
                <AccordionRow label="Label" href="/to">
                    Hello, World!
                </AccordionRow>
            )

            expect(screen.getByRole('link')).toHaveAttribute('href', '/to')
            expect(component).toMatchSnapshot()
        })
    })

    describe('when passed an `active` prop', () => {
        it('should be highlighted', () => {
            const component = render(
                <AccordionRow label="Label" active={true}>
                    Hello, World!
                </AccordionRow>
            )

            expect(component).toMatchSnapshot()
        })
    })

    describe('when passed a `collapsible` prop', () => {
        it('should render a caret for expanding and collapsing when collapsible', () => {
            const component = render(
                <AccordionRow label="Label" collapsible={true}>
                    Hello, World!
                </AccordionRow>
            )

            expect(component).toMatchSnapshot()
        })

        it('should not render a caret when not collapsible', () => {
            const component = render(
                <AccordionRow label="Label" collapsible={false}>
                    Hello, World!
                </AccordionRow>
            )

            expect(component).toMatchSnapshot()
        })
    })

    describe('when pressed', () => {
        it('should call the `onClick` callback', () => {
            const onClickMock = jest.fn()
            render(<AccordionRow onClick={onClickMock} collapsible={true} label="Label" />)

            fireEvent.click(screen.getByRole('button'))
            expect(onClickMock).toHaveBeenCalledTimes(1)
        })

        it('should call the `onToggle` callback if collapsible', () => {
            const onToggleMock = jest.fn()
            render(<AccordionRow onToggle={onToggleMock} collapsible={true} label="Label" />)

            fireEvent.click(screen.getByRole('button'))
            expect(onToggleMock).toHaveBeenCalledWith(false)

            fireEvent.click(screen.getByRole('button'))
            expect(onToggleMock).toHaveBeenCalledWith(true)
        })
    })
})
