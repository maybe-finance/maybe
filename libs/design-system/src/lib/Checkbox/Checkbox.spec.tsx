/* eslint-disable @typescript-eslint/no-empty-function */
import { fireEvent, render, screen } from '@testing-library/react'
import { Checkbox } from '.'

describe('Checkbox', () => {
    describe('when rendered with a label', () => {
        it('should display the label', () => {
            const component = render(<Checkbox onChange={() => {}} label="Checkbox label" />)

            expect(screen.getByText('Checkbox label')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })

    describe('when pressed', () => {
        it('should call the `onChange` callback', () => {
            const onChangeMock = jest.fn()
            render(<Checkbox onChange={onChangeMock} />)

            fireEvent.click(screen.getByRole('switch'))
            expect(onChangeMock).toHaveBeenCalledTimes(1)
        })
    })

    describe('when toggle is checked', () => {
        it('should display a checkmark', () => {
            const component = render(<Checkbox onChange={() => {}} checked />)

            expect(component).toMatchSnapshot()
        })
    })
})
