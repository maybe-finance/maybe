import { Button, Dialog } from '@maybe-finance/design-system'

export interface NonUSDDialogProps {
    isOpen: boolean
    onClose: () => void
}

export function NonUSDDialog({ isOpen, onClose }: NonUSDDialogProps) {
    return (
        <Dialog isOpen={isOpen} onClose={onClose}>
            <Dialog.Title>Connection Aborted</Dialog.Title>
            <Dialog.Content>
                <p>
                    Unfortunately, we&apos;re currently only supporting connections to USD accounts
                    for the duration of this beta. Once we&apos;re out of beta, our goal is to
                    support as many institutions, in as many different regions as possible.
                </p>
                <Button className="transform translate-y-8 mt-8" fullWidth onClick={onClose}>
                    Got it
                </Button>
            </Dialog.Content>
        </Dialog>
    )
}
