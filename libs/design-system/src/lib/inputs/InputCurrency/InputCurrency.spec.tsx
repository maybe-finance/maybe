import { fireEvent, render, screen } from '@testing-library/react'
import { useState } from 'react'
import { InputCurrency } from '..'

function ControlledInputCurrency(props: { [key: string]: unknown }): JSX.Element {
    const [value, setValue] = useState<number | null>(20)
    return <InputCurrency value={value} onChange={setValue} {...props} />
}

describe('InputCurrency', () => {
    describe('when rendered', () => {
        it('should display a dollar sign by default', () => {
            const component = render(<InputCurrency value={null} onChange={() => null} />)

            expect(screen.getByText('$')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
        it('should display a specified currency symbol', () => {
            const component = render(
                <InputCurrency symbol="symbol" value={null} onChange={() => null} />
            )

            expect(screen.getByText('symbol')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })

    describe('when interacted with', () => {
        it('should call `onChange` when the entered number changes', () => {
            const onChangeMock = jest.fn()

            render(<ControlledInputCurrency data-testid="input" onChange={onChangeMock} />)
            const input = screen.getByTestId('input')

            fireEvent.focus(input)
            fireEvent.change(input, { target: { value: -123 } })
            expect(onChangeMock).toHaveBeenCalledWith(123) // Negative inputs not accepted, will be converted to positive
        })
    })
})
