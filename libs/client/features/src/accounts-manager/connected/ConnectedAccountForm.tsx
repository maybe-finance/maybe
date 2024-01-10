import type { AccountCategory, AccountType } from '@prisma/client'

import { Controller, useForm } from 'react-hook-form'
import { Button, DatePicker, Input, Listbox } from '@maybe-finance/design-system'
import { AccountUtil } from '@maybe-finance/shared'
import { BrowserUtil } from '@maybe-finance/client/shared'

type FormData = {
    name: string
    categoryUser: AccountCategory
    startDate: string | null
}

type Props = {
    accountType: AccountType
    defaultValues: FormData
    onSubmit(data: FormData): void
}

export default function ConnectedAccountForm({ defaultValues, onSubmit, accountType }: Props) {
    const {
        control,
        register,
        handleSubmit,
        formState: { isSubmitting, isValid },
    } = useForm({
        mode: 'onChange',
        defaultValues,
    })

    return (
        <form onSubmit={handleSubmit(onSubmit)} data-testid="connected-account-form">
            <Input
                type="text"
                className="flex-1 bg-gray-700"
                label="Name"
                placeholder="Account Name"
                autoFocus
                {...register('name', { required: true })}
            />

            <div className="mt-4">
                <Controller
                    control={control}
                    name="categoryUser"
                    render={({ field }) => (
                        <Listbox {...field}>
                            <Listbox.Button label="Category" placeholder="Select">
                                {AccountUtil.CATEGORIES[field.value].plural}
                            </Listbox.Button>
                            <Listbox.Options>
                                {AccountUtil.CATEGORY_MAP[accountType].map((category) => (
                                    <Listbox.Option key={category.value} value={category.value}>
                                        {category.plural}
                                    </Listbox.Option>
                                ))}
                            </Listbox.Options>
                        </Listbox>
                    )}
                />
            </div>

            <div className="mt-4 mb-6">
                <Controller
                    control={control}
                    name="startDate"
                    rules={{
                        validate: (d) => BrowserUtil.validateFormDate(d, { required: false }),
                    }}
                    render={({ field, fieldState: { error } }) => {
                        return (
                            <DatePicker
                                label="Account start date"
                                popperPlacement="top"
                                error={error?.message}
                                {...field}
                            />
                        )
                    }}
                />
            </div>

            <Button type="submit" fullWidth disabled={isSubmitting || !isValid}>
                Update account
            </Button>
        </form>
    )
}
