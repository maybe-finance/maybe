import type { Story, Meta } from '@storybook/react'
import type { DialogProps } from './Dialog'
import * as React from 'react'

import Dialog from './Dialog'

// Misc UI elements for stories
import { Button, Input, FormGroup } from '../../'

export default {
    title: 'Components/Dialog',
    component: Dialog,
    parameters: {
        controls: { exclude: ['as', 'className'] },
    },
} as Meta

export const Base: Story<DialogProps> = (args) => {
    const [isOpen, setIsOpen] = React.useState(false)
    return (
        <div className="h-48 flex items-center justify-center">
            <Button onClick={() => setIsOpen(true)}>Open Dialog</Button>
            <Dialog {...args} isOpen={isOpen} onClose={() => setIsOpen(false)}>
                <Dialog.Title>Add Home</Dialog.Title>
                <Dialog.Content>
                    <div className="space-y-3">
                        <Input type="text" label="Label" />
                        <Input type="text" label="Label" />
                        <Input type="text" label="Label" />
                    </div>
                </Dialog.Content>
                <Dialog.Actions>
                    <Button type="button" onClick={() => setIsOpen(false)} fullWidth>
                        Add Home
                    </Button>
                </Dialog.Actions>
            </Dialog>
        </div>
    )
}

export const WithDescription: Story<DialogProps> = (args) => {
    const [isOpen, setIsOpen] = React.useState(false)
    return (
        <div className="h-48 flex items-center justify-center">
            <Button onClick={() => setIsOpen(true)}>Open Dialog</Button>
            <Dialog {...args} isOpen={isOpen} onClose={() => setIsOpen(false)}>
                <Dialog.Title>Add Home</Dialog.Title>
                <Dialog.Content>
                    <FormGroup className="space-y-3">
                        <Input type="text" label="Label" />
                        <Input type="text" label="Label" />
                        <Input type="text" label="Label" />
                    </FormGroup>
                </Dialog.Content>
                <Dialog.Description>
                    Removing the Business Account will remove all related transactions and
                    historical data. This will likely impact other views such as your net worth
                    dashboard.
                </Dialog.Description>
                <Dialog.Actions>
                    <Button type="button" onClick={() => setIsOpen(false)} fullWidth>
                        Add Home
                    </Button>
                </Dialog.Actions>
            </Dialog>
        </div>
    )
}

export const WithMultipleActions: Story<DialogProps> = (args) => {
    const [isOpen, setIsOpen] = React.useState(false)
    return (
        <div className="h-48 flex items-center justify-center">
            <Button onClick={() => setIsOpen(true)}>Open Dialog</Button>
            <Dialog {...args} isOpen={isOpen} onClose={() => setIsOpen(false)}>
                <Dialog.Title>Add Home</Dialog.Title>
                <Dialog.Content>
                    <div className="space-y-3">
                        <Input type="text" label="Label" />
                        <Input type="text" label="Label" />
                        <Input type="text" label="Label" />
                    </div>
                </Dialog.Content>

                <Dialog.Actions>
                    <Button
                        type="button"
                        variant="secondary"
                        onClick={() => setIsOpen(false)}
                        fullWidth
                    >
                        Cancel
                    </Button>
                    <Button
                        type="button"
                        variant="primary"
                        onClick={() => setIsOpen(false)}
                        fullWidth
                    >
                        Add Home
                    </Button>
                </Dialog.Actions>
            </Dialog>
        </div>
    )
}

export const KitchenSink: Story<DialogProps> = (args) => {
    const [isOpen, setIsOpen] = React.useState(false)
    return (
        <div className="h-48 flex items-center justify-center">
            <Button onClick={() => setIsOpen(true)}>Open Dialog</Button>
            <Dialog {...args} isOpen={isOpen} onClose={() => setIsOpen(false)}>
                <Dialog.Title>Add Home</Dialog.Title>
                <Dialog.Content>
                    <FormGroup className="space-y-3">
                        <Input type="text" label="Label" />
                        <Input type="text" label="Label" />
                        <Input type="text" label="Label" />
                    </FormGroup>
                </Dialog.Content>
                <Dialog.Description>
                    Removing the Business Account will remove all related transactions and
                    historical data. This will likely impact other views such as your net worth
                    dashboard.
                </Dialog.Description>
                <Dialog.Actions>
                    <Button
                        type="button"
                        variant="secondary"
                        onClick={() => setIsOpen(false)}
                        fullWidth
                    >
                        Cancel
                    </Button>
                    <Button
                        type="button"
                        variant="primary"
                        onClick={() => setIsOpen(false)}
                        fullWidth
                    >
                        Add
                    </Button>
                </Dialog.Actions>
            </Dialog>
        </div>
    )
}
