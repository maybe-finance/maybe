import { DateUtil, type SharedType } from '@maybe-finance/shared'
import { useAccountApi, useAccountContext } from '@maybe-finance/client/shared'
import ConnectedAccountForm from './ConnectedAccountForm'

export function EditConnectedAccount({ account }: { account: SharedType.AccountDetail }) {
    const { setAccountManager } = useAccountContext()

    const { useUpdateAccount } = useAccountApi()
    const updateAccount = useUpdateAccount()

    return (
        <ConnectedAccountForm
            accountType={account.type}
            defaultValues={{
                name: account.name,
                startDate: DateUtil.dateTransform(account.startDate),
                categoryUser: account.category,
            }}
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
