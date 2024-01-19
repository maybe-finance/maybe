import type { AccountClassification, AccountCategory } from '@prisma/client'

import { Controller } from 'react-hook-form'
import { Input, InputCurrency, DatePicker } from '@maybe-finance/design-system'
import { BrowserUtil } from '@maybe-finance/client/shared'

export type AccountValuationFieldProps = {
    control: any
    classification?: AccountClassification
    category?: AccountCategory
    currentBalanceEditable?: boolean
}

export function AccountValuationFormFields({
    control,
    classification = 'asset',
    category = 'investment',
    currentBalanceEditable = true,
}: AccountValuationFieldProps) {
    return (
        <>
            {category === 'stock' && (
                <Controller
                    control={control}
                    name="stockSymbol"
                    shouldUnregister
                    render={({ field, fieldState: { error } }) => (
                        <Input
                            {...field}
                            type="text"
                            className="mb-4"
                            label="Symbol"
                            placeholder="e.g. MCD"
                            error={error && 'Symbol is required'}
                        />
                    )}
                />
            )}

            <Controller
                control={control}
                name="startDate"
                rules={{ validate: BrowserUtil.validateFormDate }}
                render={({ field, fieldState: { error } }) => (
                    <DatePicker
                        label={classification === 'liability' ? 'Origin date' : 'Purchase date'}
                        error={error?.message}
                        popperPlacement="top"
                        {...field}
                    />
                )}
            />

            <div className="flex gap-4 my-4">
                <Controller
                    control={control}
                    name="originalBalance"
                    rules={{ required: true, validate: (val) => val >= 0 }}
                    render={({ field, fieldState: { error } }) => (
                        <InputCurrency
                            {...field}
                            label={`${
                                classification === 'liability'
                                    ? 'Start'
                                    : category === 'stock'
                                    ? 'Total purchase'
                                    : 'Purchase'
                            } value`}
                            placeholder="0"
                            error={error && 'Positive value is required'}
                        />
                    )}
                />

                {category === 'stock' && (
                    <Controller
                        control={control}
                        name="numberShares"
                        rules={{ required: true, validate: (val) => val >= 0 }}
                        shouldUnregister
                        render={({ field, fieldState: { error } }) => (
                            <Input
                                {...field}
                                type="text"
                                label="Number of shares"
                                placeholder="0"
                                error={error && 'Number of shares is required'}
                            />
                        )}
                    />
                )}

                {category !== 'stock' && currentBalanceEditable && (
                    <Controller
                        control={control}
                        name="currentBalance"
                        rules={{
                            required: currentBalanceEditable,
                            min: 0,
                        }}
                        shouldUnregister
                        render={({ field, fieldState }) => (
                            <InputCurrency
                                {...field}
                                label="Current value"
                                placeholder="0"
                                error={fieldState.error && 'Positive value is required'}
                            />
                        )}
                    />
                )}
            </div>
        </>
    )
}
