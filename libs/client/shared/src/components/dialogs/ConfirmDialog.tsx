import type { PropsWithChildren } from 'react'
import { Button, Dialog } from '@maybe-finance/design-system'

export type UnlinkAccountConfirmProps = PropsWithChildren<{
    isOpen: boolean
    onCancel: () => void
    onConfirm: () => void
    title: string
    showClose?: boolean
}>

export function ConfirmDialog({
    isOpen,
    onCancel,
    onConfirm,
    title,
    showClose = false,
    children,
}: UnlinkAccountConfirmProps) {
    return (
        <Dialog isOpen={isOpen} onClose={onCancel} showCloseButton={showClose}>
            <Dialog.Title>{title}</Dialog.Title>
            <Dialog.Content>{children}</Dialog.Content>
            <Dialog.Actions>
                <Button fullWidth variant="secondary" onClick={onCancel}>
                    Cancel
                </Button>
                <Button fullWidth variant="danger" onClick={onConfirm}>
                    Unlink Account
                </Button>
            </Dialog.Actions>
        </Dialog>
    )
}
