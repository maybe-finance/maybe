import { type NumberFormatValues, PatternFormat } from 'react-number-format'
import { DateTime } from 'luxon'
import { useCallback } from 'react'
import { Input } from '../inputs'

export interface DatePickerInput {
    onChange: (value: string) => void
    value?: string
    error?: string
    hasError?: boolean
    onError?: (error: string) => void
    minDate?: string
    maxDate?: string
    className?: string
}

export function DatePickerInput({
    value,
    onChange,
    error,
    hasError,
    onError,
    minDate,
    maxDate,
    className,
}: DatePickerInput) {
    const handleInputValueChange = useCallback(
        (date: NumberFormatValues) => {
            if (date.value.length === 8) {
                let errorMessage = ''

                /**
                 * react-number-format guarantees that we will always have valid user inputs, so
                 * we can rely on the length of the user input string to determine when the date
                 * is valid and when we should update it in the UI
                 */
                const month = +date.value.substring(0, 2)
                const day = +date.value.substring(2, 4)
                const year = +date.value.substring(4, 8)

                const inputDate = DateTime.fromObject({ month, day, year })

                // Make sure date is valid
                if (!inputDate.isValid) errorMessage = 'Invalid date provided'

                const min = DateTime.fromISO(
                    minDate || DateTime.now().minus({ years: 50 }).toISODate()
                )

                const max = DateTime.fromISO(maxDate || DateTime.now().toISODate())

                if (inputDate < min) errorMessage = `Date must be greater than ${min.toISODate()}`
                if (inputDate > max) errorMessage = `Date must be less than ${max.toISODate()}`

                if (errorMessage) {
                    onError && onError(errorMessage)
                } else {
                    onError && onError('')
                }

                // Pass value back in YYYY-MM-DD format
                onChange(inputDate.toFormat('yyyy-MM-dd'))
            }
        },
        [minDate, maxDate, onChange, onError]
    )

    return (
        <PatternFormat
            customInput={Input} // passes all props below to <Input /> - https://github.com/s-yadav/react-number-format#custom-inputs
            format="## / ## / ####"
            mask={['M', 'M', 'D', 'D', 'Y', 'Y', 'Y', 'Y']}
            value={value ? DateTime.fromISO(value).toFormat('MM / dd / yyyy') : ''} // must pass an empty string for the "undefined" condition to trigger a re-render
            error={error}
            hasError={!!error || hasError}
            onValueChange={handleInputValueChange}
            className={className}
            placeholder="MM / DD / YYYY"
            inputClassName="text-center"
        />
    )
}
