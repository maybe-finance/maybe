/* eslint-disable @typescript-eslint/no-empty-function */
import { fireEvent, render, screen } from '@testing-library/react'
import { Listbox } from './'

// Not tested too thoroughly, most logic is covered by Headless UI base
describe('Listbox', () => {
    describe('when closed', () => {
        it('should render the button', () => {
            const component = render(
                <Listbox value="Option 1" onChange={() => {}}>
                    <Listbox.Button>Select...</Listbox.Button>
                    <Listbox.Options>
                        <Listbox.Option value="Option 1">Option 1</Listbox.Option>
                    </Listbox.Options>
                </Listbox>
            )

            expect(screen.getByText('Select...')).toBeVisible()
            expect(screen.queryByText('Option 1')).not.toBeVisible()
            expect(component).toMatchSnapshot()
        })
    })

    describe('when opened', () => {
        it('should render the button and the items', () => {
            const component = render(
                <Listbox value="Option 1" onChange={() => {}}>
                    <Listbox.Button>Select...</Listbox.Button>
                    <Listbox.Options>
                        <Listbox.Option value="Option 1">Option 1</Listbox.Option>
                        <Listbox.Option value="Option 2" disabled={true}>
                            Option 2
                        </Listbox.Option>
                    </Listbox.Options>
                </Listbox>
            )

            fireEvent.click(screen.getByText('Select...'))
            ;['Select...', 'Option 1', 'Option 2'].forEach((text) =>
                expect(screen.getByText(text)).toBeVisible()
            )
            expect(component).toMatchSnapshot()
        })
    })

    describe('when an option is pressed', () => {
        it('should call the `onChange` callback', () => {
            const onChangeMock = jest.fn()
            render(
                <Listbox value="Option 1" onChange={onChangeMock}>
                    <Listbox.Button>Select...</Listbox.Button>
                    <Listbox.Options>
                        <Listbox.Option value="Option 1">Option 1</Listbox.Option>
                    </Listbox.Options>
                </Listbox>
            )

            fireEvent.click(screen.getByText('Select...'))
            fireEvent.click(screen.getByText('Option 1'))
            expect(onChangeMock).toHaveBeenCalledWith('Option 1')
        })
    })
})
