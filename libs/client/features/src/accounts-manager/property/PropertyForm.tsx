import type { CreatePropertyFields, UpdatePropertyFields } from '@maybe-finance/client/shared'
import { Button, Input } from '@maybe-finance/design-system'
import { DateUtil } from '@maybe-finance/shared'
import { useForm } from 'react-hook-form'
import { AccountValuationFormFields } from '../AccountValuationFormFields'

type Props =
    | {
          mode: 'create'
          defaultValues: CreatePropertyFields
          onSubmit(data: CreatePropertyFields): void
      }
    | {
          mode: 'update'
          defaultValues: UpdatePropertyFields
          onSubmit(data: UpdatePropertyFields): void
      }

export default function PropertyForm({ mode, defaultValues, onSubmit }: Props) {
    const {
        register,
        control,
        handleSubmit,
        watch,
        formState: { errors, isSubmitting, isValid },
    } = useForm<CreatePropertyFields & UpdatePropertyFields>({
        mode: 'onChange',
        defaultValues,
    })

    const startDate = watch('startDate')
    const currentBalanceEditable = !DateUtil.isToday(startDate)

    return (
        <form onSubmit={handleSubmit(onSubmit)} data-testid="property-form">
            <section className="space-y-4 mb-8">
                <h6 className="text-white uppercase">Location</h6>
                <div className="space-y-4">
                    <Input
                        type="text"
                        label="Country"
                        placeholder="Enter country"
                        {...register('country', { required: true })}
                    />

                    <Input
                        type="text"
                        label="Address"
                        placeholder="Enter address"
                        error={errors.line1 && 'Address is required'}
                        {...register('line1', { required: true })}
                    />

                    <Input
                        type="text"
                        label="City"
                        placeholder="Enter city"
                        error={errors.city && 'City is required'}
                        {...register('city', { required: true })}
                    />

                    <div className="flex gap-4">
                        <Input
                            type="text"
                            label="State"
                            placeholder="Enter state"
                            error={errors.state && 'State is required'}
                            {...register('state', { required: true })}
                        />

                        <Input
                            type="text"
                            label="Postal Code"
                            placeholder="Enter postal code"
                            error={errors.zip && 'Postal code is required'}
                            {...register('zip', { required: true })}
                        />
                    </div>
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
                data-testid="property-form-submit"
            >
                {mode === 'create' ? 'Add property' : 'Update property'}
            </Button>
        </form>
    )
}
