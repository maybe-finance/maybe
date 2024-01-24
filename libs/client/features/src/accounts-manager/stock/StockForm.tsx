import type { CreateVehicleFields, UpdateVehicleFields } from '@maybe-finance/client/shared'
import { Button, Input } from '@maybe-finance/design-system'
import { DateUtil } from '@maybe-finance/shared'
import { useForm } from 'react-hook-form'
import { AccountValuationFormFields } from '../AccountValuationFormFields'

type Props =
    | {
          mode: 'create'
          defaultValues: CreateVehicleFields
          onSubmit(data: CreateVehicleFields): void
      }
    | {
          mode: 'update'
          defaultValues: UpdateVehicleFields
          onSubmit(data: UpdateVehicleFields): void
      }

export default function StockForm({ mode, defaultValues, onSubmit }: Props) {
    const {
        register,
        control,
        handleSubmit,
        watch,
        formState: { errors, isSubmitting, isValid },
    } = useForm<CreateVehicleFields & UpdateVehicleFields>({
        mode: 'onChange',
        defaultValues,
    })

    const startDate = watch('startDate')
    const currentBalanceEditable = !startDate || !DateUtil.isToday(startDate)

    return (
        <form onSubmit={handleSubmit(onSubmit)} data-testid="vehicle-form">
            <section className="space-y-4 mb-8">
                <h6 className="text-white uppercase">Details</h6>
                <div className="space-y-4">
                    <Input
                        type="text"
                        label="Investment account"
                        placeholder="Account Name"
                        error={errors.make && 'Account is required'}
                        {...register('make', { required: true })}
                    />

                    <Input
                        type="text"
                        label="Stock"
                        placeholder="Enter stock"
                        error={errors.model && 'Stock is required'}
                        {...register('model', { required: true })}
                    />
                </div>
            </section>

            {mode === 'create' && (
                <section className="space-y-4">
                    <h6 className="text-white uppercase">Valuation</h6>
                    <div>
                        <AccountValuationFormFields
                            control={control}
                            currentBalanceEditable={currentBalanceEditable}
                        />
                    </div>
                </section>
            )}

            <Button
                type="submit"
                fullWidth
                disabled={isSubmitting || !isValid}
                data-testid="stock-form-submit"
            >
                {mode === 'create' ? 'Add stock' : 'Update'}
            </Button>
        </form>
    )
}
