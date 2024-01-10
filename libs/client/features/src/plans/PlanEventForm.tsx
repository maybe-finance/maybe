import type { SharedType } from '@maybe-finance/shared'
import { Controller, useForm } from 'react-hook-form'
import { Button, Input, InputCurrency, Listbox } from '@maybe-finance/design-system'
import { RiArrowDownLine, RiArrowUpLine, RiRepeatLine } from 'react-icons/ri'
import upperFirst from 'lodash/upperFirst'
import { PlanRangeInput, usePlanContext } from '.'
import type { O } from 'ts-toolbelt'
import { NumericFormat } from 'react-number-format'
import Decimal from 'decimal.js'

export type PlanEventValues = Pick<
    SharedType.PlanEvent,
    | 'name'
    | 'frequency'
    | 'initialValue'
    | 'initialValueRef'
    | 'rate'
    | 'startYear'
    | 'startMilestoneId'
    | 'endYear'
    | 'endMilestoneId'
>

export type PlanEventFormProps = {
    mode: 'create' | 'update'
    flow: 'income' | 'expense'
    initialValues?: Partial<PlanEventValues>
    onSubmit: (data: O.Nullable<PlanEventValues, 'initialValue'>) => void
    onDelete?: () => void
}

export function PlanEventForm({
    mode,
    flow,
    initialValues,
    onSubmit,
    onDelete,
}: PlanEventFormProps) {
    const { planStartYear } = usePlanContext()

    const {
        control,
        handleSubmit,
        formState: { isSubmitting, isValid, touchedFields },
        register,
        watch,
        setValue,
        setError,
        clearErrors,
        getFieldState,
    } = useForm<PlanEventValues>({
        mode: 'onChange',
        defaultValues: {
            frequency: 'yearly',
            startYear: planStartYear,
            initialValue: new Decimal(0),
            initialValueRef: null,
            rate: new Decimal(0),
            ...initialValues,
        },
    })

    const [frequency, startYear, startMilestoneId, endYear, endMilestoneId] = watch([
        'frequency',
        'startYear',
        'startMilestoneId',
        'endYear',
        'endMilestoneId',
    ])

    return (
        <form
            className="flex flex-col grow"
            onSubmit={handleSubmit(({ initialValue, initialValueRef, ...data }) => {
                // if user hasn't modified initialValue, then preserve the ref
                if (initialValueRef && !touchedFields.initialValue) {
                    onSubmit({ ...data, initialValue: null, initialValueRef })
                } else {
                    onSubmit({ ...data, initialValue, initialValueRef: null })
                }
            })}
        >
            <h4>{flow === 'income' ? 'Income' : 'Expense'} Event</h4>
            <h6 className="mt-4 uppercase">Overview</h6>

            <Input
                type="text"
                label="Name"
                placeholder={initialValues?.name ?? 'Event'}
                className="mt-2"
                {...register('name', { required: true })}
            />

            <Controller
                control={control}
                name="initialValue"
                rules={{
                    required: 'Amount is required',
                    validate: (val) => (val && val.lte(0) ? 'Amount must be positive' : true),
                }}
                render={({ field, fieldState: { error } }) => {
                    return (
                        <InputCurrency
                            {...field}
                            value={field.value?.toNumber() ?? null}
                            onChange={(val) => field.onChange(val != null ? new Decimal(val) : val)}
                            label="Amount"
                            error={error?.message}
                            className="mt-2"
                        />
                    )
                }}
            />

            <h6 className="mt-4 uppercase">Time</h6>

            <Controller
                control={control}
                name="frequency"
                render={({ field }) => (
                    <Listbox value={field.value} onChange={field.onChange} className="mt-2">
                        <Listbox.Button label="Frequency" icon={RiRepeatLine}>
                            {frequency ? upperFirst(frequency) : 'Once'}
                        </Listbox.Button>
                        <Listbox.Options>
                            <Listbox.Option value="yearly">Yearly</Listbox.Option>
                            <Listbox.Option value="monthly">Monthly</Listbox.Option>
                            <Listbox.Option value={undefined}>Once</Listbox.Option>
                        </Listbox.Options>
                    </Listbox>
                )}
            />

            <div className="flex space-x-3 mt-4">
                <PlanRangeInput
                    type="start"
                    value={{ year: startYear, milestoneId: startMilestoneId }}
                    onChange={(value) => {
                        setValue('startYear', value.year)
                        setValue('startMilestoneId', value.milestoneId)
                    }}
                    className="w-1/2"
                />

                <PlanRangeInput
                    type="end"
                    value={{ year: endYear, milestoneId: endMilestoneId }}
                    onChange={(value) => {
                        setValue('endYear', value.year)
                        setValue('endMilestoneId', value.milestoneId)

                        if (value.year && startYear && value.year < startYear)
                            setError('endYear', { type: 'custom', message: 'Must be after start' })
                        else clearErrors('endYear')
                    }}
                    className="w-1/2"
                    error={getFieldState('endYear').error?.message}
                />
            </div>

            <h6 className="mt-4 uppercase">Change</h6>

            <Controller
                control={control}
                name="rate"
                rules={{ required: true }}
                render={({ field, fieldState: { error } }) => {
                    const sign: '+' | '-' = field.value.isPositive() ? '+' : '-'

                    return (
                        <div className="flex space-x-3 mt-2">
                            <Listbox
                                value={sign}
                                onChange={() => field.onChange(field.value.negated())}
                                className="w-1/2"
                            >
                                <Listbox.Button
                                    label="Yearly change"
                                    icon={sign === '+' ? RiArrowUpLine : RiArrowDownLine}
                                >
                                    {sign === '+' ? 'Increase' : 'Decrease'}
                                </Listbox.Button>
                                <Listbox.Options>
                                    <Listbox.Option value="+">Increase</Listbox.Option>
                                    <Listbox.Option value="-">Decrease</Listbox.Option>
                                </Listbox.Options>
                            </Listbox>

                            <NumericFormat
                                label="Value"
                                customInput={Input}
                                className="w-1/2"
                                inputClassName="w-full"
                                fixedRightOverride={
                                    <span className="text-gray-100 text-base">%</span>
                                }
                                decimalScale={2}
                                allowLeadingZeros
                                fixedDecimalScale
                                error={error && 'Change value is required'}
                                allowNegative={false}
                                value={field.value.times(100).toString()}
                                onValueChange={({ value }) => {
                                    if (value) field.onChange(new Decimal(value).div(100))
                                }}
                            />
                        </div>
                    )
                }}
            />

            <div className="flex flex-col grow justify-end mt-4 mb-20 space-y-3">
                {mode === 'create' && (
                    <Button type="submit" disabled={isSubmitting || !isValid}>
                        Create
                    </Button>
                )}
                {mode === 'update' && (
                    <>
                        <Button type="submit" disabled={isSubmitting || !isValid}>
                            Update
                        </Button>
                        <Button variant="warn" disabled={isSubmitting} onClick={onDelete}>
                            Delete
                        </Button>
                    </>
                )}
            </div>
        </form>
    )
}
