import type { AccountType } from '@prisma/client'
import { Controller, useForm } from 'react-hook-form'
import { Button, Input, Listbox } from '@maybe-finance/design-system'
import { AccountUtil, DateUtil } from '@maybe-finance/shared'
import { AccountValuationFormFields } from '../AccountValuationFormFields'
import type { CreateLiabilityFields, UpdateLiabilityFields } from '@maybe-finance/client/shared'
import { NumericFormat } from 'react-number-format'
import { DateTime } from 'luxon'

const loanTypes = [
    {
        label: 'Home Loan',
        value: 'mortgage',
    },
    {
        label: 'Student Loan',
        value: 'student',
    },
    {
        label: 'Other Loan',
        value: 'other',
    },
]

const loanInterestTypes = [
    {
        label: 'Fixed',
        value: 'fixed',
    },
    {
        label: 'Variable',
        value: 'variable',
    },
    {
        label: 'Adjustable Rate Mortgage',
        value: 'arm',
    },
]

type Props =
    | {
          mode: 'create'
          accountType?: never
          defaultValues: CreateLiabilityFields
          onSubmit(data: CreateLiabilityFields): void
      }
    | {
          mode: 'update'
          accountType: AccountType
          defaultValues: UpdateLiabilityFields
          onSubmit(data: UpdateLiabilityFields): void
      }

export default function LiabilityForm({ mode, defaultValues, onSubmit, accountType }: Props) {
    const {
        register,
        watch,
        control,
        handleSubmit,
        formState: { errors, isSubmitting, isValid },
    } = useForm<CreateLiabilityFields & UpdateLiabilityFields>({
        mode: 'onChange',
        defaultValues,
    })

    const [startDate, interestType, maturityDate, categoryUser] = watch([
        'startDate',
        'interestType',
        'maturityDate',
        'categoryUser',
    ])

    const currentBalanceEditable = !DateUtil.isToday(startDate)

    const unroundedTerm =
        maturityDate && startDate
            ? DateUtil.datetimeTransform(maturityDate)
                  .diff(DateUtil.datetimeTransform(startDate), 'months')
                  .toObject().months
            : null

    const loanTerm = unroundedTerm ? Math.round(unroundedTerm) : null

    // If in update mode, certain categories cannot be changed (e.g. cannot change from "other" to a "loan" after account has been created)
    const categoryList =
        mode === 'create' ? AccountUtil.LIABILITY_CATEGORIES : AccountUtil.CATEGORY_MAP[accountType]

    return (
        <form onSubmit={handleSubmit(onSubmit)} data-testid="liability-form">
            <h6 className="text-white uppercase">Details</h6>

            <section className="space-y-4 my-4">
                <Input
                    type="text"
                    label="Name"
                    error={errors.name && 'Name is required'}
                    className="mb-4"
                    placeholder={
                        categoryUser === 'loan' ? 'e.g. Mortgage Loan' : 'e.g. Debt to a friend'
                    }
                    {...register('name', { required: true })}
                />

                <Controller
                    control={control}
                    name="categoryUser"
                    render={({ field }) => (
                        <Listbox {...field}>
                            <Listbox.Button label="Category" placeholder="Select">
                                {AccountUtil.CATEGORIES[field.value].plural}
                            </Listbox.Button>
                            <Listbox.Options>
                                {categoryList.map((category) => (
                                    <Listbox.Option key={category.value} value={category.value}>
                                        {category.plural}
                                    </Listbox.Option>
                                ))}
                            </Listbox.Options>
                        </Listbox>
                    )}
                />
            </section>

            {categoryUser === 'loan' && <h6 className="uppercase mt-6">Loan Terms</h6>}

            <section className="my-4 space-y-4">
                {categoryUser === 'loan' && (
                    <>
                        <Controller
                            control={control}
                            name="loanType"
                            render={({ field }) => (
                                <Listbox {...field}>
                                    <Listbox.Button label="Loan type" placeholder="Select">
                                        {loanTypes.find((t) => t.value === field.value)?.label}
                                    </Listbox.Button>
                                    <Listbox.Options>
                                        {loanTypes.map((type) => (
                                            <Listbox.Option key={type.value} value={type.value}>
                                                {type.label}
                                            </Listbox.Option>
                                        ))}
                                    </Listbox.Options>
                                </Listbox>
                            )}
                        />

                        <Controller
                            control={control}
                            name="interestType"
                            render={({ field }) => (
                                <Listbox {...field}>
                                    <Listbox.Button label="Interest type" placeholder="Select">
                                        {
                                            loanInterestTypes.find((t) => t.value === field.value)
                                                ?.label
                                        }
                                    </Listbox.Button>
                                    <Listbox.Options>
                                        {loanInterestTypes.map((type) => (
                                            <Listbox.Option key={type.value} value={type.value}>
                                                {type.label}
                                            </Listbox.Option>
                                        ))}
                                    </Listbox.Options>
                                </Listbox>
                            )}
                        />
                    </>
                )}

                {(mode === 'create' || (mode === 'update' && categoryUser === 'loan')) && (
                    <div>
                        {categoryUser !== 'loan' && (
                            <h6 className="text-white uppercase">Balance</h6>
                        )}
                        <AccountValuationFormFields
                            control={control}
                            currentBalanceEditable={currentBalanceEditable}
                            classification="liability"
                        />
                    </div>
                )}

                {categoryUser === 'loan' && (
                    <>
                        <div className="flex gap-4">
                            <Controller
                                control={control}
                                name="maturityDate"
                                rules={{ required: true }}
                                render={({ field }) => (
                                    <NumericFormat
                                        name={field.name}
                                        label="Loan term"
                                        customInput={Input}
                                        fixedRightOverride={
                                            <span className="text-gray-100 text-base">months</span>
                                        }
                                        placeholder="360"
                                        allowNegative={false}
                                        value={loanTerm}
                                        onValueChange={(value) => {
                                            const newMaturityDate = DateUtil.datetimeTransform(
                                                startDate
                                            )
                                                ?.plus({ months: value.floatValue })
                                                .toISODate()

                                            if (newMaturityDate) {
                                                field.onChange(newMaturityDate)
                                            }
                                        }}
                                    />
                                )}
                            />

                            {interestType === 'fixed' && (
                                <Controller
                                    control={control}
                                    name="interestRate"
                                    rules={{ required: true, validate: (val) => !val || val >= 0 }}
                                    render={({ field }) => (
                                        <NumericFormat
                                            {...field}
                                            label="Interest rate %"
                                            customInput={Input}
                                            placeholder={'5.50'}
                                            inputClassName="w-full"
                                            decimalScale={2}
                                            allowLeadingZeros
                                            fixedDecimalScale
                                            allowNegative={false}
                                            value={field.value}
                                            onValueChange={(value) => {
                                                field.onChange(value.value)
                                            }}
                                        />
                                    )}
                                />
                            )}
                        </div>

                        {interestType !== 'fixed' && (
                            <p className="text-sm text-gray-100 my-4">
                                We are still working on full support for non-standard loan terms.
                                Your details will be saved, but your metrics shown will be limited.
                            </p>
                        )}
                    </>
                )}
            </section>

            <Button
                type="submit"
                fullWidth
                disabled={isSubmitting || !isValid}
                data-testid="liability-form-submit"
            >
                {mode === 'create' ? 'Add debt' : 'Update'}
            </Button>
        </form>
    )
}
