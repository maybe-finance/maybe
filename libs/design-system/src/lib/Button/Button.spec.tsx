import { fireEvent, render, screen } from '@testing-library/react'
import Button from './Button'

describe('Button', () => {
    describe('when rendered with text', () => {
        it('should display the text', () => {
            const component = render(<Button>Hello, World!</Button>)

            expect(screen.getByText('Hello, World!')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })

    describe('when pressed', () => {
        it('should call the `onClick` callback', () => {
            const onClickMock = jest.fn()
            render(<Button onClick={onClickMock}>Hello, World!</Button>)

            fireEvent.click(screen.getByRole('button'))
            expect(onClickMock).toHaveBeenCalledTimes(1)
        })
    })

    describe('when passed an `href` value', () => {
        it('should render as an <a> element', () => {
            const component = render(<Button href="https://example.com">Hello, World!</Button>)
            // Ideally we'd actually assert the tag name here, but I can't see a good way to do that
            expect(component).toMatchSnapshot()
        })
    })

    describe('when passed an `as` prop', () => {
        it('should render as the specified element', () => {
            const component = render(<Button as="div">Hello, World!</Button>)
            // Ideally we'd actually assert the tag name here, but I can't see a good way to do that
            expect(component).toMatchSnapshot()
        })
    })
})
