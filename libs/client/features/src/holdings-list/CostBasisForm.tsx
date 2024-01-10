import { Button, InputCurrency, RadioGroup, Tooltip } from '@maybe-finance/design-system'
import { Controller, useForm } from 'react-hook-form'
import { RiQuestionLine } from 'react-icons/ri'

type FormValues =
    | { type: 'calculated'; costBasisUser: null }
    | { type: 'manual'; costBasisUser: number }

type Props = {
    defaultValues: FormValues
    onSubmit(data: FormValues): void
    onClose(): void
    isEstimate: boolean
}

export function CostBasisForm({ defaultValues, onSubmit, onClose, isEstimate }: Props) {
    const {
        watch,
        control,
        handleSubmit,
        formState: { isSubmitting, isValid },
    } = useForm<FormValues>({ mode: 'onChange', defaultValues })

    const type = watch('type')

    return (
        <form onSubmit={handleSubmit(onSubmit)}>
            <Controller
                control={control}
                name="type"
                render={({ field }) => (
                    <RadioGroup value={field.value} onChange={field.onChange}>
                        <RadioGroup.Option value="calculated">
                            <RadioGroup.Label className="flex items-center">
                                {isEstimate ? 'Use estimated average' : 'Use recommended value'}
                                {isEstimate && (
                                    <Tooltip
                                        content={
                                            <span className="text-base text-gray-50">
                                                We do our best to calculate exact cost basis, but in
                                                some cases where we have missing data from our
                                                providers, we rely on a crude average calculation.
                                            </span>
                                        }
                                    >
                                        <span className="ml-1.5">
                                            <RiQuestionLine className="w-5 h-5" />
                                        </span>
                                    </Tooltip>
                                )}
                            </RadioGroup.Label>
                        </RadioGroup.Option>
                        <RadioGroup.Option value="manual">
                            <RadioGroup.Label className="flex items-center">
                                Use manual value
                            </RadioGroup.Label>
                        </RadioGroup.Option>
                    </RadioGroup>
                )}
            />

            {type === 'manual' && (
                <Controller
                    control={control}
                    name="costBasisUser"
                    rules={{ required: 'Value required' }}
                    render={({ field, fieldState: { error } }) => {
                        return (
                            <InputCurrency
                                {...field}
                                className="mt-2"
                                fixedRightOverride={
                                    <span className="whitespace-nowrap">per share</span>
                                }
                                error={error?.message}
                            />
                        )
                    }}
                />
            )}

            <div className="flex items-center justify-end gap-2 mt-3">
                <Button variant="secondary" onClick={onClose}>
                    Cancel
                </Button>
                <Button type="submit" disabled={isSubmitting || !isValid}>
                    Update
                </Button>
            </div>
        </form>
    )
}
