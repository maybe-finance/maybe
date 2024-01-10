import { useEffect, useRef, useState } from 'react'
import { Alert, Button, Dialog } from '@maybe-finance/design-system'

const COUNT_DOWN_SECONDS = 3

export interface DeleteUserModalProps {
    isOpen: boolean
    onClose: () => void
    onConfirm: () => void
}

const Emphasized = ({ children }: { children: React.ReactNode }) => (
    <span className="text-white">{children}</span>
)

export function DeleteUserModal({ isOpen, onClose, onConfirm }: DeleteUserModalProps) {
    const cancelButton = useRef<HTMLButtonElement>(null)
    const [countDown, setCountDown] = useState(COUNT_DOWN_SECONDS)
    const countDownIntervalId = useRef<number | null>(null)

    // Reset count down when modal is opened
    useEffect(() => {
        if (isOpen === true) {
            setCountDown(COUNT_DOWN_SECONDS)
            if (countDownIntervalId.current != null)
                window.clearInterval(countDownIntervalId.current)
            countDownIntervalId.current = window.setInterval(
                () => setCountDown((countDown) => countDown - 1),
                1000
            )
        }
    }, [isOpen])

    return (
        <Dialog isOpen={isOpen} onClose={onClose} initialFocus={cancelButton}>
            <Dialog.Title>Delete Maybe Account</Dialog.Title>
            <Dialog.Content>
                <Alert isVisible={true} variant="error">
                    This action cannot be undone
                </Alert>
                <p className="mt-4 text-base text-gray-50">
                    Are you sure you want to delete your Maybe account? All{' '}
                    <Emphasized>accounts</Emphasized>, <Emphasized>balances</Emphasized>, and{' '}
                    <Emphasized>other data</Emphasized> will be deleted{' '}
                    <Emphasized>permanently</Emphasized>.
                </p>
            </Dialog.Content>
            <Dialog.Actions>
                <Button ref={cancelButton} fullWidth variant="secondary" onClick={onClose}>
                    Cancel
                </Button>
                <Button fullWidth variant="danger" disabled={countDown > 0} onClick={onConfirm}>
                    Delete Account
                    {countDown > 0 && <span className="tabular-nums">&nbsp;({countDown} s)</span>}
                </Button>
            </Dialog.Actions>
        </Dialog>
    )
}
