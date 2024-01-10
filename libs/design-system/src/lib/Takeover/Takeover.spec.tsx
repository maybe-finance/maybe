import { render, screen } from '@testing-library/react'
import { Takeover } from './'

describe('Takeover', () => {
    describe('when rendered with `open` prop true', () => {
        it('should display the contents', () => {
            const onToggleMock = jest.fn()
            const component = render(
                <Takeover open={true} onClose={onToggleMock}>
                    Takeover content
                </Takeover>
            )

            expect(screen.getByText('Takeover content')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })
})
