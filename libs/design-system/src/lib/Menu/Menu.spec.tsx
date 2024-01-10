import { fireEvent, render, screen } from '@testing-library/react'
import { Menu } from './'

// Not tested too thoroughly, most logic is covered by Headless UI base
describe('Menu', () => {
    describe('when closed', () => {
        it('should render the button', () => {
            const component = render(
                <Menu>
                    <Menu.Button>Click Me</Menu.Button>
                    <Menu.Items>
                        <Menu.Item>Option 1</Menu.Item>
                    </Menu.Items>
                </Menu>
            )

            expect(screen.getByText('Click Me')).toBeVisible()
            expect(screen.queryByText('Option 1')).not.toBeVisible()
            expect(component).toMatchSnapshot()
        })
    })

    describe('when opened', () => {
        it('should render the button and the items', () => {
            const component = render(
                <Menu>
                    <Menu.Button>Click Me</Menu.Button>
                    <Menu.Items>
                        <Menu.Item>Option 1</Menu.Item>
                        <Menu.Item disabled={true}>Option 2</Menu.Item>
                    </Menu.Items>
                </Menu>
            )

            fireEvent.click(screen.getByText('Click Me'))
            ;['Click Me', 'Option 1', 'Option 2'].forEach((text) =>
                expect(screen.getByText(text)).toBeVisible()
            )
            expect(component).toMatchSnapshot()
        })
    })

    describe('when an option is pressed', () => {
        it('should call the `onClick` callback', () => {
            const onClickMock = jest.fn()
            render(
                <Menu>
                    <Menu.Button>Click Me</Menu.Button>
                    <Menu.Items>
                        <Menu.Item onClick={onClickMock}>Option 1</Menu.Item>
                    </Menu.Items>
                </Menu>
            )

            fireEvent.click(screen.getByText('Click Me'))
            fireEvent.click(screen.getByText('Option 1'))
            expect(onClickMock).toHaveBeenCalledTimes(1)
        })
    })
})
