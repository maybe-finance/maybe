import { fireEvent, render, screen } from '@testing-library/react'
import { Input } from '..'

describe('Input', () => {
    describe('when rendered', () => {
        it('should display a placeholder when passed', () => {
            const component = render(<Input type="text" placeholder="Placeholder" />)

            expect(screen.getByPlaceholderText('Placeholder')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
        it('should display a label when passed', () => {
            const component = render(<Input type="text" label="Label" />)

            expect(screen.getByLabelText('Label')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
        it('should display a color hint when passed', () => {
            const component = render(<Input type="text" colorHint="teal" />)

            expect(component).toMatchSnapshot()
        })
        it('should render plainly when no extra props are passed', () => {
            const component = render(<Input type="text" />)

            expect(component).toMatchSnapshot()
        })
    })

    describe('when interacted with', () => {
        it('should call `onFocus` and `onBlur` callbacks', () => {
            const onFocusMock = jest.fn(),
                onBlurMock = jest.fn()
            render(
                <Input data-testid="input" type="text" onFocus={onFocusMock} onBlur={onBlurMock} />
            )
            const input = screen.getByTestId('input')

            fireEvent.focus(input)
            expect(onFocusMock).toHaveBeenCalledTimes(1)
            fireEvent.blur(input)
            expect(onBlurMock).toHaveBeenCalledTimes(1)
        })

        it('should call the `onChange` callback on change', () => {
            const onChangeMock = jest.fn()
            render(<Input data-testid="input" type="text" onChange={onChangeMock} />)
            const input = screen.getByTestId('input')

            fireEvent.focus(input)
            fireEvent.change(input, {
                target: { value: 'abc' },
            })
            expect(onChangeMock).toHaveBeenCalledTimes(1)
        })
    })
})
