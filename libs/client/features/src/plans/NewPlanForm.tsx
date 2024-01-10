import { Controller, useForm } from 'react-hook-form'
import { Button, Input } from '@maybe-finance/design-system'
import { NumberUtil } from '@maybe-finance/shared'
import { NumericFormat } from 'react-number-format'

export type NewPlanValues = {
    name: string
    lifeExpectancy: number
}

type Props = {
    initialValues?: Partial<NewPlanValues>
    onSubmit(data: NewPlanValues): void
}

export function NewPlanForm({ initialValues, onSubmit }: Props) {
    const { control, handleSubmit, formState, register } = useForm<NewPlanValues>({
        mode: 'onChange',
        defaultValues: {
            ...initialValues,
        },
    })

    const { isSubmitting, isValid } = formState

    return (
        <form onSubmit={handleSubmit(onSubmit)}>
            <Input
                type="text"
                label="Plan name"
                placeholder={initialValues?.name ?? 'Retirement'}
                {...register('name', { required: true })}
            />

            <Controller
                control={control}
                name="lifeExpectancy"
                rules={{ required: true }}
                render={({ field, fieldState: { error } }) => (
                    <NumericFormat
                        label="Life expectancy"
                        customInput={Input}
                        placeholder={NumberUtil.format(
                            initialValues?.lifeExpectancy ?? 85,
                            'decimal'
                        )}
                        className="mt-4"
                        error={error && 'Life expectancy is required'}
                        fixedRightOverride={<span className="text-gray-100 text-base">years</span>}
                        allowNegative={false}
                        value={field.value}
                        onValueChange={(value) =>
                            field.onChange(value.value ? parseFloat(value.value) : value.value)
                        }
                    />
                )}
            />

            <div className="flex justify-end mt-4">
                <Button type="submit" disabled={isSubmitting || !isValid}>
                    Create Plan
                </Button>
            </div>
        </form>
    )
}
