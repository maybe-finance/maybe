import React, { forwardRef } from 'react'
import { NumericFormat, type NumericFormatProps } from 'react-number-format'
import { Input, type InputProps } from '..'

export type InputCurrencyProps = Omit<InputProps, 'value' | 'defaultValue' | 'onChange'> &
    Omit<NumericFormatProps, 'value' | 'onChange' | 'type'> & {
        value: number | null
        onChange(value: number | null): void

        /** Currency symbol to appear on the left side of the input */
        symbol?: string
    }

/**
 * Controlled input for numerical currency values
 */
function InputCurrency(
    { value, onChange, type, symbol = '$', allowNegative = false, ...rest }: InputCurrencyProps,
    ref: React.Ref<HTMLInputElement>
) {
    // https://github.com/s-yadav/react-number-format#custom-inputs
    return (
        <NumericFormat
            customInput={Input}
            getInputRef={ref}
            value={value}
            onValueChange={(value) => {
                onChange(value.floatValue ?? null)
            }}
            decimalScale={2}
            thousandSeparator
            allowNegative={allowNegative}
            fixedLeftOverride={symbol}
            {...rest}
            type={type as any} // conflicting types between React and Number format
        />
    )
}

export default forwardRef<HTMLInputElement, InputCurrencyProps>(InputCurrency)
