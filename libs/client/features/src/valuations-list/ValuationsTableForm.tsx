import { BrowserUtil, useValuationApi } from '@maybe-finance/client/shared'
import { Button, DatePicker, InputCurrency } from '@maybe-finance/design-system'
import { PerformanceMetric } from './PerformanceMetric'
import classNames from 'classnames'
import { Controller, useForm } from 'react-hook-form'
import { RiCheckLine, RiCloseFill, RiKeyboardBoxLine } from 'react-icons/ri'
import type { Row } from '@tanstack/react-table'
import type { ValuationRowData } from './types'

type FormValues = { date: string; amount: number }

export function ValuationsTableForm({
    row,
    onEdit,
}: {
    row: Row<ValuationRowData>
    onEdit(rowIndex?: number): void
}) {
    const data = row.original!

    const initialValues = {
        amount: data.amount.toNumber(),
        date: data.date,
    }
    const onClose = () => onEdit(undefined)

    const { valuationId, accountId } = data

    const { useUpdateValuation, useCreateValuation } = useValuationApi()
    const updateQuery = useUpdateValuation()
    const createQuery = useCreateValuation()

    const { control, handleSubmit } = useForm<FormValues>({
        mode: 'onChange',
        defaultValues: { ...initialValues, date: initialValues.date.toISODate() },
    })

    const onSubmit = ({ date, amount }: FormValues) => {
        const preparedData = {
            date,
            amount,
        }

        const onSuccess = onClose

        if (valuationId) {
            updateQuery.mutate({ id: valuationId, data: preparedData }, { onSuccess })
        } else {
            createQuery.mutate({ id: accountId!, data: preparedData }, { onSuccess })
        }
    }

    return (
        <>
            <td className="flex items-center justify-start p-0 font-normal py-4 pl-4 rounded-l-lg bg-gray-700">
                <div
                    className={classNames(
                        'h-12 w-12 flex items-center justify-center shrink-0 mr-4 rounded-xl',
                        valuationId ? 'bg-pink/10 text-pink' : 'bg-white/10 text-gray-100'
                    )}
                >
                    <RiKeyboardBoxLine className="w-6 h-6" />
                </div>

                <form onSubmit={handleSubmit(onSubmit)} className="contents">
                    <Controller
                        control={control}
                        name="date"
                        rules={{ validate: BrowserUtil.validateFormDate }}
                        render={({ field, fieldState: { error } }) => {
                            return (
                                <DatePicker
                                    popperPlacement="top-start"
                                    error={error?.message}
                                    {...field}
                                />
                            )
                        }}
                    />
                </form>
            </td>
            <td className="flex items-center justify-end font-normal py-4 text-right bg-gray-700">
                <form onSubmit={handleSubmit(onSubmit)} className="contents">
                    <Controller
                        control={control}
                        name="amount"
                        rules={{ required: true, validate: (val) => val >= 0 }}
                        render={({ field, fieldState }) => (
                            <InputCurrency
                                {...field}
                                error={fieldState.error && 'Positive value is required'}
                            />
                        )}
                    />
                </form>
            </td>
            <td className="flex items-center justify-between font-normal py-4 bg-gray-700">
                <div className="ml-4 space-x-2">
                    <Button variant="icon" onClick={handleSubmit(onSubmit)}>
                        <RiCheckLine className="w-6 h-6" />
                    </Button>
                    <Button variant="icon" onClick={onClose}>
                        <RiCloseFill className="w-6 h-6" />
                    </Button>
                </div>
                <div>{valuationId && <PerformanceMetric trend={data.period} />}</div>
            </td>
            <td className="flex items-center justify-end font-normal py-4 pr-4 text-right rounded-r-lg bg-gray-700">
                {valuationId && <PerformanceMetric trend={data.total} />}
            </td>
        </>
    )
}
