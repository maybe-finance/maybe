import { useAccountApi, useAccountContext } from '@maybe-finance/client/shared'
import { Button, Dialog } from '@maybe-finance/design-system'

export interface DeleteAccountProps {
    accountId: number
    accountName: string
    onDelete?: () => void
}

export function DeleteAccount({ accountId, accountName, onDelete }: DeleteAccountProps) {
    const { setAccountManager } = useAccountContext()

    const { useDeleteAccount } = useAccountApi()
    const deleteAccount = useDeleteAccount()

    return (
        <div>
            <Dialog.Content>
                <p className="text-base text-gray-50">
                    Deleting <span className="text-white">{accountName}</span> will permanently
                    remove this account and all other related data. This will impact other views
                    such as your net worth dashboard.
                </p>
                <div className="mt-4 grid grid-cols-2 gap-4">
                    <Button variant="secondary" onClick={() => setAccountManager({ view: 'idle' })}>
                        Cancel
                    </Button>
                    <Button
                        variant="danger"
                        disabled={deleteAccount.isLoading}
                        onClick={async () => {
                            setAccountManager({ view: 'idle' })
                            await deleteAccount.mutate(accountId)
                            if (onDelete) {
                                onDelete()
                            }
                        }}
                    >
                        Delete
                    </Button>
                </div>
            </Dialog.Content>
        </div>
    )
}
