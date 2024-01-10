/* eslint-disable @typescript-eslint/no-empty-function */
import { fireEvent, render, screen } from '@testing-library/react'
import { Toggle } from '.'

describe('Toggle', () => {
    describe('when rendered with a screenreader label', () => {
        it('should display the label to screenreaders', () => {
            const component = render(<Toggle onChange={() => {}} screenReaderLabel="SRLabel" />)

            expect(screen.getByText('SRLabel')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })

    describe('when pressed', () => {
        it('should call the `onClick` callback', () => {
            const onClickMock = jest.fn()
            render(<Toggle screenReaderLabel="SRLabel" onChange={onClickMock} />)

            fireEvent.click(screen.getByRole('switch'))
            expect(onClickMock).toHaveBeenCalledTimes(1)
        })
    })

    describe('when toggle is checked', () => {
        it('should have the toggle disc moved to the right', () => {
            const component = render(
                <Toggle screenReaderLabel="SRLabel" onChange={() => {}} checked />
            )

            expect(component).toMatchSnapshot()
        })
    })

    describe('when passing a className', () => {
        it('should merge them and show all classNames', () => {
            render(
                <Toggle
                    screenReaderLabel="SRLabel"
                    onChange={() => {}}
                    className="test-classname"
                />
            )

            expect(screen.getByRole('switch')).toHaveClass('test-classname')
            // className cursor-pointer exists on the toggle by default
            expect(screen.getByRole('switch')).toHaveClass('cursor-pointer')
        })
    })
})
