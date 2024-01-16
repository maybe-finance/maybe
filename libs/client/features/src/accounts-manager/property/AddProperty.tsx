import {
    useAccountContext,
    useAccountApi,
    type CreatePropertyFields,
} from '@maybe-finance/client/shared'
import { DateTime } from 'luxon'
import PropertyForm from './PropertyForm'

export function AddProperty({ defaultValues }: { defaultValues: Partial<CreatePropertyFields> }) {
    const { setAccountManager } = useAccountContext()
    const { useCreateAccount } = useAccountApi()
    const createAccount = useCreateAccount()

    return (
        <div>
            <PropertyForm
                mode="create"
                defaultValues={{
                    line1: defaultValues.line1 ?? '',
                    city: defaultValues.city ?? '',
                    state: defaultValues.state ?? '',
                    zip: defaultValues.zip ?? '',
                    country: defaultValues.country ?? '',
                    startDate: defaultValues.startDate ?? null,
                    originalBalance: defaultValues.originalBalance ?? null,
                    currentBalance: defaultValues.currentBalance ?? null,
                }}
                onSubmit={async ({
                    line1,
                    city,
                    state,
                    zip,
                    country,
                    originalBalance,
                    currentBalance,
                    startDate,
                }) => {
                    await createAccount.mutateAsync({
                        type: 'PROPERTY',
                        categoryUser: 'property',
                        name: line1,
                        startDate,
                        valuations: {
                            originalBalance,
                            currentBalance,
                            currentDate: DateTime.now().toISODate(),
                        },
                        propertyMeta: {
                            address: {
                                line1,
                                city,
                                state,
                                zip,
                                country,
                            },
                        },
                    })

                    setAccountManager({ view: 'idle' })
                }}
            />
        </div>
    )
}
