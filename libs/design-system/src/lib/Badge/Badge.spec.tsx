import { render, screen } from '@testing-library/react'
import { Badge } from './'

describe('Badge', () => {
    describe('when rendered with text', () => {
        it('should display the text', () => {
            const component = render(<Badge variant="teal">Hello, World!</Badge>)

            expect(screen.getByText('Hello, World!')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })

    describe('when passed a true `highlighted` prop', () => {
        it('should render as a highlighted Badge', () => {
            const component = render(
                <Badge variant="teal" highlighted={true}>
                    Hello, World!
                </Badge>
            )

            expect(component).toMatchSnapshot()
        })
    })

    describe('when passed an `as` prop', () => {
        it('should render as the specified element', () => {
            const component = render(
                <Badge variant="teal" as="a">
                    Hello, World!
                </Badge>
            )
            // Ideally we'd actually assert the tag name here, but I can't see a good way to do that
            expect(component).toMatchSnapshot()
        })
    })
})
