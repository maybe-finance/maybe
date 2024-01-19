import type { CreateAssetFields, UpdateAssetFields } from '@maybe-finance/client/shared'
import type { AccountType } from '@prisma/client'
import { Controller, useForm } from 'react-hook-form'
import { Button, Input, Listbox } from '@maybe-finance/design-system'
import { AccountUtil, DateUtil } from '@maybe-finance/shared'
import { AccountValuationFormFields } from '../AccountValuationFormFields'
import { useMemo } from 'react'

type Props =
    | {
          mode: 'create'
          accountType?: never
          defaultValues: CreateAssetFields
          onSubmit(data: CreateAssetFields): void
      }
    | {
          mode: 'update'
          accountType?: AccountType
          defaultValues: UpdateAssetFields
          onSubmit(data: UpdateAssetFields): void
      }

export default function AssetForm({ mode, defaultValues, onSubmit, accountType }: Props) {
    const { register, watch, control, handleSubmit, formState } = useForm<
        CreateAssetFields & UpdateAssetFields
    >({
        mode: 'onChange',
        defaultValues,
    })

    const { errors, isSubmitting, isValid } = formState
    const [startDate] = watch(['startDate'])
    const currentBalanceEditable = !startDate || !DateUtil.isToday(startDate)
    const [categoryValue] = watch(['categoryUser'])
    const categoryList = useMemo(() => {
        const { stock, cash, investment, crypto, valuable, other } = AccountUtil.CATEGORIES

        if (mode === 'create') {
            return [stock, cash, investment, crypto, valuable, other]
        } else {
            return AccountUtil.CATEGORY_MAP[accountType!]
        }
    }, [mode, accountType])

    return (
        <form onSubmit={handleSubmit(onSubmit)} data-testid="asset-form">
            <section className="space-y-4 mb-8">
                <h6 className="text-white uppercase">Details</h6>
                <div className="space-y-4">
                    <Input
                        type="text"
                        label="Name"
                        placeholder="e.g. Physical Cash"
                        error={errors.name && 'Name is required'}
                        className="mb-4"
                        {...register('name', { required: true })}
                    />
                </div>

                <div className="space-y-4">
                    <Controller
                        control={control}
                        name="categoryUser"
                        render={({ field }) => {
                            return (
                                <Listbox {...field}>
                                    <Listbox.Button label="Category" placeholder="Select">
                                        {AccountUtil.CATEGORIES[field.value].plural}
                                    </Listbox.Button>
                                    <Listbox.Options>
                                        {categoryList.map((category) => (
                                            <Listbox.Option
                                                key={category.value}
                                                value={category.value}
                                            >
                                                {category.plural}
                                            </Listbox.Option>
                                        ))}
                                    </Listbox.Options>
                                </Listbox>
                            )
                        }}
                    />
                </div>
            </section>

            {mode === 'create' && (
                <section className="space-y-4">
                    <h6 className="text-white uppercase">Valuation</h6>
                    <div>
                        <AccountValuationFormFields
                            control={control}
                            category={categoryValue}
                            currentBalanceEditable={currentBalanceEditable}
                        />
                    </div>
                </section>
            )}

            <Button
                type="submit"
                fullWidth
                disabled={isSubmitting || !isValid}
                data-testid="asset-form-submit"
            >
                {mode === 'create' ? 'Add asset' : 'Update asset'}
            </Button>
        </form>
    )
}
