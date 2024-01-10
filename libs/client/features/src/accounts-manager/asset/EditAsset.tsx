import type { SharedType } from '@maybe-finance/shared'
import { useAccountApi, useAccountContext } from '@maybe-finance/client/shared'
import AssetForm from './AssetForm'

export function EditAsset({ account }: { account: SharedType.AccountDetail }) {
    const { setAccountManager } = useAccountContext()

    const { useUpdateAccount } = useAccountApi()
    const updateAccount = useUpdateAccount()

    return (
        <AssetForm
            mode="update"
            accountType={account.type}
            defaultValues={{ name: account.name, categoryUser: account.category }}
            onSubmit={async (data) => {
                await updateAccount.mutateAsync({
                    id: account.id,
                    data: {
                        provider: account.provider,
                        data: {
                            type: account.type,
                            ...data,
                        },
                    },
                })

                setAccountManager({ view: 'idle' })
            }}
        />
    )
}
