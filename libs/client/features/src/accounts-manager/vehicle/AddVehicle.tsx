import {
    type CreateVehicleFields,
    useAccountApi,
    useAccountContext,
} from '@maybe-finance/client/shared'
import { DateTime } from 'luxon'
import VehicleForm from './VehicleForm'

export function AddVehicle({ defaultValues }: { defaultValues: Partial<CreateVehicleFields> }) {
    const { setAccountManager } = useAccountContext()
    const { useCreateAccount } = useAccountApi()
    const createAccount = useCreateAccount()

    return (
        <div>
            <VehicleForm
                mode="create"
                defaultValues={{
                    make: defaultValues.make ?? '',
                    model: defaultValues.model ?? '',
                    year: defaultValues.year ?? '',
                    startDate: defaultValues.startDate ?? null,
                    originalBalance: defaultValues.originalBalance ?? null,
                    currentBalance: defaultValues.currentBalance ?? null,
                }}
                onSubmit={async ({
                    originalBalance,
                    currentBalance,
                    make,
                    model,
                    year,
                    startDate,
                }) => {
                    await createAccount.mutateAsync({
                        type: 'VEHICLE',
                        categoryUser: 'vehicle',
                        valuations: {
                            originalBalance,
                            currentBalance,
                            currentDate: DateTime.now().toISODate(),
                        },
                        vehicleMeta: {
                            make,
                            model,
                            year: parseInt(year),
                        },
                        name: `${make} ${model}`,
                        startDate,
                    })

                    setAccountManager({ view: 'idle' })
                }}
            />
        </div>
    )
}
