import {
    type CreateAssetFields,
    useAccountApi,
    useAccountContext,
} from '@maybe-finance/client/shared'
import { DateTime } from 'luxon'
import AssetForm from './AssetForm'

export function AddAsset({ defaultValues }: { defaultValues: Partial<CreateAssetFields> }) {
    const { setAccountManager } = useAccountContext()
    const { useCreateAccount } = useAccountApi()
    const createAccount = useCreateAccount()

    return (
        <div>
            <AssetForm
                mode="create"
                defaultValues={{
                    name: defaultValues.name ?? 'Cash Asset',
                    categoryUser: defaultValues.categoryUser ?? 'cash',
                    startDate: defaultValues.startDate ?? null,
                    currentBalance: defaultValues.currentBalance ?? null,
                    originalBalance: defaultValues.originalBalance ?? null,
                }}
                onSubmit={async ({ originalBalance, currentBalance, ...rest }) => {
                    await createAccount.mutateAsync({
                        type: 'OTHER_ASSET',
                        valuations: {
                            originalBalance,
                            currentBalance,
                            currentDate: DateTime.now().toISODate(),
                        },
                        ...rest,
                    })

                    setAccountManager({ view: 'idle' })
                }}
            />
        </div>
    )
}
