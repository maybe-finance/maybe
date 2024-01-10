import type { ToastVariant } from '.'
import { render, screen } from '@testing-library/react'
import { Toast } from '.'

describe('Toast', () => {
    describe('when rendered with text', () => {
        it('should display the text', () => {
            render(<Toast>Hello, World!</Toast>)

            expect(screen.getByText('Hello, World!')).toBeInTheDocument()
        })
    })

    const variants: ToastVariant[] = ['info', 'success', 'error']

    test.each(variants)('should render properly as the %s variant', (variant) => {
        const component = render(<Toast variant={variant}>Hello, World!</Toast>)
        expect(component).toMatchSnapshot()
    })
})
