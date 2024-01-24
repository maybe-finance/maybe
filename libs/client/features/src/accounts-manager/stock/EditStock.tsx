import type { SharedType } from '@maybe-finance/shared'
import {
    type UpdateVehicleFields,
    useAccountApi,
    useAccountContext,
} from '@maybe-finance/client/shared'
import StockForm from './StockForm'

export function EditVehicle({ account }: { account: SharedType.AccountDetail }) {
    const { setAccountManager } = useAccountContext()

    const { useUpdateAccount } = useAccountApi()
    const updateAccount = useUpdateAccount()

    return (
        <StockForm
            mode="update"
            defaultValues={account.vehicleMeta as UpdateVehicleFields}
            onSubmit={async ({ make, model, year, ...rest }) => {
                await updateAccount.mutateAsync({
                    id: account.id,
                    data: {
                        provider: account.provider,
                        data: {
                            type: account.type,
                            categoryUser: 'vehicle',
                            name: `${make} ${model}`,
                            vehicleMeta: {
                                make,
                                model,
                                year: parseInt(year),
                            },
                            ...rest,
                        },
                    },
                })

                setAccountManager({ view: 'idle' })
            }}
        />
    )
}
