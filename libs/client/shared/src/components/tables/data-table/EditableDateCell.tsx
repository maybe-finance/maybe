import { useCallback } from 'react'
import cn from 'classnames'
import { DateTime } from 'luxon'
import { Controller, useForm } from 'react-hook-form'
import { RiCheckLine, RiCloseLine } from 'react-icons/ri'
import { PatternFormat } from 'react-number-format'

// This component interacts with date values as strings in the format YYYY-MM-DD
export type EditableDateCellProps = {
    initialValue?: string
    onSubmit(value: string): void
}

export function EditableDateCell({ initialValue, onSubmit }: EditableDateCellProps) {
    const fromFormattedDate = useCallback((value: string) => {
        return DateTime.fromFormat(value, 'MM / dd / yyyy')
    }, [])

    const { control, handleSubmit, reset } = useForm({
        defaultValues: { cellValue: initialValue },
        reValidateMode: 'onSubmit',
    })

    return (
        <div className="group text-white-300 focus-within:bg-gray-800">
            <form
                className="flex items-center"
                onSubmit={handleSubmit(({ cellValue }) => {
                    if (cellValue) {
                        onSubmit(fromFormattedDate(cellValue).toFormat('yyyy-MM-dd'))
                    }
                })}
            >
                <Controller
                    control={control}
                    name="cellValue"
                    rules={{
                        validate: (v) => {
                            if (!v) return false

                            const dateObj = fromFormattedDate(v)
                            const minDate = DateTime.fromISO('1980-01-01')
                            const maxDate = DateTime.local()

                            if (!dateObj.isValid) return false
                            if (dateObj < minDate) return false
                            if (dateObj > maxDate) return false

                            return true
                        },
                    }}
                    render={({ field: { onChange, ...field }, fieldState }) => (
                        <PatternFormat
                            {...field}
                            onValueChange={(v) => onChange(v.formattedValue)}
                            format="## / ## / ####"
                            mask={['M', 'M', 'D', 'D', 'Y', 'Y', 'Y', 'Y']}
                            placeholder="MM / DD / YYYY"
                            className={cn(
                                'w-full bg-transparent text-base border-0 focus:ring-0',
                                fieldState.invalid && 'text-red'
                            )}
                            autoComplete="off"
                        />
                    )}
                />

                <div className="hidden pr-1 group-focus-within:flex">
                    <button
                        type="button"
                        onClick={(e) => {
                            reset({ cellValue: initialValue })
                            e.currentTarget.blur()
                        }}
                    >
                        <RiCloseLine className="w-5 h-5 hover:opacity-80" />
                    </button>
                    <button type="submit" onClick={(e) => e.currentTarget.blur()}>
                        <RiCheckLine className="w-5 h-5 hover:opacity-80" />
                    </button>
                </div>
            </form>
        </div>
    )
}
