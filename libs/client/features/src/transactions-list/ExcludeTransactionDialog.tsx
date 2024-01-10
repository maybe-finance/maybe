import { useTransactionApi } from '@maybe-finance/client/shared'
import { Button, Dialog } from '@maybe-finance/design-system'
import type { SharedType } from '@maybe-finance/shared'

export interface ExcludeTransactionDialogProps {
    transaction: SharedType.AccountTransaction
    excluding: boolean
    isOpen: boolean
    onClose: (excluded: boolean) => void
}

export function ExcludeTransactionDialog({
    transaction,
    excluding,
    isOpen,
    onClose,
}: ExcludeTransactionDialogProps) {
    const { useUpdateTransaction } = useTransactionApi()

    const updateTransaction = useUpdateTransaction()

    return (
        <Dialog
            isOpen={isOpen}
            onClose={() => onClose(transaction.excluded)}
            showCloseButton={false}
        >
            <Dialog.Title>{excluding ? 'Exclude from' : 'Include in'} insights</Dialog.Title>
            <Dialog.Content>
                <p className="mt-4 text-base text-gray-50">
                    {excluding ? (
                        <>
                            Excluding this transaction will prevent it from impacting your income,
                            expense, and debt insights.
                        </>
                    ) : (
                        <>
                            Including this transaction will allow it to impact your income, expense,
                            and debt insights.
                        </>
                    )}
                </p>
                <div className="mt-8 grid grid-cols-2 gap-4">
                    <Button variant="secondary" onClick={() => onClose(transaction.excluded)}>
                        Cancel
                    </Button>
                    <Button
                        variant="primary"
                        disabled={updateTransaction.isLoading}
                        onClick={async () => {
                            await updateTransaction.mutateAsync({
                                id: transaction.id,
                                data: { excluded: excluding },
                            })
                            onClose(excluding)
                        }}
                    >
                        {excluding ? 'Exclude' : 'Include'}
                    </Button>
                </div>
            </Dialog.Content>
        </Dialog>
    )
}
