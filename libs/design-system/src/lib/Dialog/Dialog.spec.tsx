import { render, screen } from '@testing-library/react'
import { Dialog } from './'

describe('Dialog', () => {
    describe('when rendered with `open` prop true', () => {
        it('should display the modals contents', () => {
            const onToggleMock = jest.fn()
            const component = render(
                <Dialog isOpen={true} onClose={onToggleMock}>
                    <Dialog.Title>Dialog Title</Dialog.Title>
                    <Dialog.Content>Dialog Content</Dialog.Content>
                    <Dialog.Description>Dialog Description</Dialog.Description>
                    <Dialog.Actions>Dialog Actions</Dialog.Actions>
                </Dialog>
            )

            expect(screen.getByText('Dialog Title')).toBeInTheDocument()
            expect(screen.getByText('Dialog Content')).toBeInTheDocument()
            expect(screen.getByText('Dialog Description')).toBeInTheDocument()
            expect(screen.getByText('Dialog Actions')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })
})
