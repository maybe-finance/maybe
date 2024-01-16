import type { SharedType } from '@maybe-finance/shared'
import {
    type UpdatePropertyFields,
    useAccountApi,
    useAccountContext,
} from '@maybe-finance/client/shared'
import PropertyForm from './PropertyForm'

export function EditProperty({ account }: { account: SharedType.AccountDetail }) {
    const { setAccountManager } = useAccountContext()

    const { useUpdateAccount } = useAccountApi()
    const updateAccount = useUpdateAccount()

    return (
        <PropertyForm
            mode="update"
            defaultValues={(account.propertyMeta as any)?.address as UpdatePropertyFields}
            onSubmit={async ({ country, line1, city, state, zip, ...rest }) => {
                await updateAccount.mutateAsync({
                    id: account.id,
                    data: {
                        provider: account.provider,
                        data: {
                            type: account.type,
                            categoryUser: 'property',
                            name: line1,
                            propertyMeta: {
                                address: {
                                    line1,
                                    city,
                                    state,
                                    zip,
                                    country,
                                },
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
