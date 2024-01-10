import { Alert, Button } from '@maybe-finance/design-system'
import { useState } from 'react'
import { useUserApi } from '@maybe-finance/client/shared'
import { DeleteUserModal } from './DeleteUserModal'

export function DeleteUserButton({ onDelete }: { onDelete: () => void }) {
    const { useDelete } = useUserApi()

    const deleteUser = useDelete({
        onSuccess() {
            if (onDelete) onDelete()
        },
        onError(err) {
            console.error('Failed to delete user', err)
        },
    })

    const [isOpen, setIsOpen] = useState(false)

    return (
        <>
            <Button
                variant="danger"
                onClick={() => setIsOpen(true)}
                disabled={deleteUser.isLoading}
            >
                {deleteUser.isLoading
                    ? 'Deleting Maybe Account...'
                    : deleteUser.isSuccess
                    ? 'Account Deleted'
                    : 'Delete Maybe Account'}
            </Button>
            <Alert isVisible={deleteUser.isError} variant="error" className="mt-2">
                We ran into issues deleting your account. Please contact us for assistance.
            </Alert>
            <DeleteUserModal
                isOpen={isOpen}
                onClose={() => setIsOpen(false)}
                onConfirm={() => {
                    setIsOpen(false)
                    deleteUser.mutate({})
                }}
            />
        </>
    )
}
