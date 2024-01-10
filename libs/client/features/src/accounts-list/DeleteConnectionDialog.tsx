import { useAccountConnectionApi } from '@maybe-finance/client/shared'
import { Alert, Button, Dialog } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'

export interface DeleteConnectionDialogProps {
    connection: SharedType.ConnectionWithAccounts
    isOpen: boolean
    onClose: () => void
}

export function DeleteConnectionDialog({
    connection,
    isOpen,
    onClose,
}: DeleteConnectionDialogProps) {
    const { useDeleteConnection } = useAccountConnectionApi()

    const deleteConnection = useDeleteConnection()

    return (
        <Dialog isOpen={isOpen} onClose={onClose} showCloseButton={false}>
            <Dialog.Title>Delete account?</Dialog.Title>
            <Dialog.Content>
                <Alert isVisible variant="error">
                    This action cannot be undone
                </Alert>
                <p className="mt-4 text-base text-gray-50">
                    Deleting <span className="text-white">{connection.name}</span> will permanently
                    remove <span className="text-white">{connection.accounts.length} accounts</span>{' '}
                    and all other related data. This will impact other views such as your net worth
                    dashboard.
                </p>
                <div className="mt-8 grid grid-cols-2 gap-4">
                    <Button variant="secondary" onClick={onClose}>
                        Cancel
                    </Button>
                    <Button
                        variant="danger"
                        disabled={deleteConnection.isLoading}
                        onClick={() => deleteConnection.mutate(connection.id)}
                    >
                        Delete
                    </Button>
                </div>
            </Dialog.Content>
        </Dialog>
    )
}
