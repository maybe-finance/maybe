import {
    type CreateStockFields,
    useAccountApi,
    useAccountContext,
} from '@maybe-finance/client/shared'
import { DateTime } from 'luxon'
import StockForm from './StockForm'

// STOCKTODO - Change CreateStockFields
export function AddStock({ defaultValues }: { defaultValues: Partial<CreateStockFields> }) {
    const { setAccountManager } = useAccountContext()
    const { useCreateAccount } = useAccountApi()
    const createAccount = useCreateAccount()

    return (
        <div>
            <StockForm
                mode="create"
                defaultValues={{
                    account_id: defaultValues.account_id ?? null,
                    stock: defaultValues.stock ?? '',
                    startDate: defaultValues.startDate ?? null,
                    originalBalance: defaultValues.originalBalance ?? null,
                    shares: defaultValues.shares ?? null,
                }}
                onSubmit={async ({ account_id, stock, startDate, originalBalance, shares }) => {
                    // STOCKTODO : Figure out what all is required to create a stock account
                    await createAccount.mutateAsync({
                        // STOCKTODO : Change type based on whether you choose to go with the 'STOCK' type
                        type: 'INVESTMENT',
                        // STOCKTODO : Figure out what the categoryUser is
                        categoryUser: 'vehicle',
                        // STOCKTODO : Figure out what the valuations are
                        valuations: {
                            originalBalance,
                            currentBalance,
                            currentDate: DateTime.now().toISODate(),
                        },
                        // STOCKTODO : Figure out what the vehicle meta is
                        vehicleMeta: {
                            make,
                            model,
                            year: parseInt(year),
                        },
                        // STOCKTODO : Change this according this to stock
                        name: `${make} ${model}`,
                        startDate,
                    })

                    setAccountManager({ view: 'idle' })
                }}
            />
        </div>
    )
}
