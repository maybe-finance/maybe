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
                        label="Make"
                        placeholder="Enter make"
                        error={errors.make && 'Make is required'}
                        {...register('make', { required: true })}
                    />

                    <Input
                        type="text"
                        label="Model"
                        placeholder="Enter model"
                        error={errors.model && 'Model is required'}
                        {...register('model', { required: true })}
                    />

                    <Input
                        type="text"
                        label="Year"
                        placeholder="Enter year"
                        error={errors.year && 'A valid year is required'}
                        {...register('year', {
                            required: true,
                            validate: (v) =>
                                v != null &&
                                parseInt(v) > 1800 &&
                                parseInt(v) < new Date().getFullYear() + 2,
                        })}
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
                data-testid="vehicle-form-submit"
            >
                {mode === 'create' ? 'Add vehicle' : 'Update'}
            </Button>
        </form>
    )
}
