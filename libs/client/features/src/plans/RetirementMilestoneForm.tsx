import { Button, Input, InputCurrency, Listbox } from '@maybe-finance/design-system'
import { DateUtil } from '@maybe-finance/shared'
import upperFirst from 'lodash/upperFirst'
import { useState } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { usePlanContext } from './PlanContext'

type FormData = {
    monthlySpending: number
    age?: number
    year?: number
}

type RefMode = {
    value: 'age' | 'year'
    display: string
}

type Props = {
    mode: 'create' | 'update'
    defaultValues: Partial<FormData>
    onSubmit: (data: Required<Omit<FormData, 'age'>>) => void
}

const refModes: RefMode[] = [
    {
        value: 'age',
        display: 'At age',
    },
    {
        value: 'year',
        display: 'In the year',
    },
]

export function RetirementMilestoneForm({ mode, onSubmit, defaultValues }: Props) {
    const { userAge, planStartYear, planEndYear } = usePlanContext()

    const {
        register,
        control,
        handleSubmit,
        watch,
        setValue,
        formState: { errors, isSubmitting, isValid },
    } = useForm<FormData>({
        mode: 'onChange',
        shouldUnregister: true,
        defaultValues,
    })

    const [refMode, setRefMode] = useState<RefMode>(userAge ? refModes[0] : refModes[1])
    const [age, year] = watch(['age', 'year'])

    return (
        <form
            onSubmit={handleSubmit((data) =>
                onSubmit({
                    monthlySpending: data.monthlySpending,
                    year:
                        refMode.value === 'age'
                            ? DateUtil.ageToYear(data.age!, userAge)
                            : data.year!,
                })
            )}
        >
            <span className="text-gray-50 text-base inline-block pb-1">I want to retire</span>
            <div className="flex gap-2">
                <Listbox
                    value={refMode}
                    onChange={(refMode: RefMode) => {
                        if (refMode.value === 'age' && year) {
                            setValue('age', DateUtil.yearToAge(year, userAge))
                        }

                        if (refMode.value === 'year' && age) {
                            setValue('year', DateUtil.ageToYear(age, userAge))
                        }

                        setRefMode(refMode)
                    }}
                    className="w-1/2"
                >
                    <Listbox.Button>{refMode.display}</Listbox.Button>
                    <Listbox.Options>
                        {refModes.map((m) => (
                            <Listbox.Option key={m.value} value={m}>
                                {m.display}
                            </Listbox.Option>
                        ))}
                    </Listbox.Options>
                </Listbox>

                {refMode.value === 'age' && (
                    <Input
                        type="text"
                        error={
                            errors.age &&
                            (errors.age.type === 'validate'
                                ? `Age must be between ${DateUtil.yearToAge(
                                      planStartYear,
                                      userAge
                                  )} and ${DateUtil.yearToAge(planEndYear, userAge)}`
                                : 'Age required')
                        }
                        className="w-1/2"
                        {...register('age', {
                            required: true,
                            validate: (age) => {
                                if (!age) return true
                                const year = DateUtil.ageToYear(age, userAge)
                                return year >= planStartYear && year <= planEndYear
                            },
                            valueAsNumber: true,
                        })}
                    />
                )}

                {refMode.value === 'year' && (
                    <Input
                        type="text"
                        error={
                            errors.year &&
                            (errors.year.type === 'validate'
                                ? `Year must be between ${planStartYear} and ${planEndYear}`
                                : 'Year required')
                        }
                        className="w-1/2"
                        {...register('year', {
                            required: true,
                            validate: (year) => {
                                if (!year) return true
                                return year >= planStartYear && year <= planEndYear
                            },
                            valueAsNumber: true,
                        })}
                    />
                )}
            </div>

            {mode === 'create' && (
                <Controller
                    control={control}
                    name="monthlySpending"
                    rules={{ required: true }}
                    render={({ field, fieldState }) => (
                        <InputCurrency
                            label="In retirement I expect to spend"
                            error={fieldState.error && 'Monthly spending is required'}
                            className="mt-4"
                            fixedRightOverride={
                                <span className="text-base text-gray-100">per month</span>
                            }
                            {...field}
                        />
                    )}
                />
            )}

            <Button
                type="submit"
                fullWidth
                className="mt-6"
                disabled={isSubmitting || !isValid}
                data-testid="retirement-milestone-form-submit"
            >
                {upperFirst(mode)}
            </Button>
        </form>
    )
}
