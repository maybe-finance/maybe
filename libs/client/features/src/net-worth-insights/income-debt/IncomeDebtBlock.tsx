import { Button, InputCurrency, Tooltip } from '@maybe-finance/design-system'
import { NumberUtil } from '@maybe-finance/shared'
import { Prisma } from '@prisma/client'
import classNames from 'classnames'
import { useCallback, useMemo, useState } from 'react'
import {
    RiArrowGoBackLine,
    RiArrowLeftDownLine,
    RiArrowRightUpLine,
    RiCheckFill,
    RiCloseFill,
    RiPencilLine,
    RiQuestionLine,
} from 'react-icons/ri'

export interface IncomeDebtBlock {
    variant: 'Income' | 'Debt'
    value: Prisma.Decimal
    calculatedValue: Prisma.Decimal
    onChange: (value: Prisma.Decimal) => void
}
export function IncomeDebtBlock({
    variant,
    value: valueProp,
    calculatedValue,
    onChange,
}: IncomeDebtBlock) {
    const [value, setValue] = useState(valueProp)
    const [isEditing, setIsEditing] = useState(false)

    const formattedValue = useMemo(() => NumberUtil.format(value, 'currency', {}), [value])

    const confirmEdit = useCallback(() => {
        onChange(value)
        setIsEditing(false)
    }, [onChange, value])

    const revertManual = useCallback(() => {
        setValue(calculatedValue)
        onChange(calculatedValue)
    }, [calculatedValue, onChange])

    return (
        <div
            className={classNames(
                'my-3 p-3 rounded-lg bg-gray-600 text-gray-100',
                variant === 'Income' && 'from-teal-500/5 to-gray-800/5 bg-gradient-to-t',
                variant === 'Debt' && 'from-red-500/5 to-gray-800/5 bg-gradient-to-t'
            )}
        >
            <div className="flex items-center">
                {variant === 'Income' && (
                    <>
                        <RiArrowRightUpLine className="w-5 h-5 text-teal mr-1" />
                        <span>Income</span>
                        <Tooltip content="Your monthly income" className="max-w-[350px]">
                            <span>
                                <RiQuestionLine className="w-4 h-4 text-gray-100 mx-1.5" />
                            </span>
                        </Tooltip>
                    </>
                )}

                {variant === 'Debt' && (
                    <>
                        <RiArrowLeftDownLine className="w-5 h-5 text-red mr-1" />
                        <span className="text-gray-100">Debt payments</span>
                        <Tooltip content="Your monthly debt payments" className="max-w-[350px]">
                            <span>
                                <RiQuestionLine className="w-4 h-4 text-gray-100 mx-1.5" />
                            </span>
                        </Tooltip>
                    </>
                )}

                <div className="grow flex justify-end space-x-1">
                    {isEditing ? (
                        <>
                            <Tooltip content="Cancel">
                                <Button
                                    variant="icon"
                                    onClick={() => {
                                        setValue(valueProp)
                                        setIsEditing(false)
                                    }}
                                >
                                    <RiCloseFill className="w-4 h-4" />
                                </Button>
                            </Tooltip>
                            <Tooltip content="Confirm or press Enter ⏎">
                                <Button variant="icon" onClick={confirmEdit}>
                                    <RiCheckFill className="w-4 h-4" />
                                </Button>
                            </Tooltip>
                        </>
                    ) : (
                        <>
                            {!valueProp.equals(calculatedValue) && (
                                <Tooltip content="Revert to non-manual value">
                                    <Button variant="icon" onClick={revertManual}>
                                        <RiArrowGoBackLine className="w-4 h-4" />
                                    </Button>
                                </Tooltip>
                            )}
                            <Tooltip content={`Edit ${variant === 'Income' ? 'income' : 'debt'}`}>
                                <Button variant="icon" onClick={() => setIsEditing(true)}>
                                    <RiPencilLine className="w-4 h-4" />
                                </Button>
                            </Tooltip>
                        </>
                    )}
                </div>
            </div>

            <div
                className={classNames(
                    'h-12 flex items-end',
                    variant === 'Income' && 'text-teal',
                    variant === 'Debt' && 'text-red'
                )}
            >
                {isEditing ? (
                    <InputCurrency
                        variant={variant === 'Income' ? 'positive' : 'negative'}
                        autoFocus
                        value={+value.toFixed(2)}
                        onChange={(v) => setValue(new Prisma.Decimal(v ?? 0))}
                        onKeyUp={(e) => e.key === 'Enter' && confirmEdit()}
                    />
                ) : (
                    <>
                        <h3>{formattedValue.split('.')[0]}</h3>
                        <h5 className="mb-0.5">
                            {formattedValue.split('.')[1] ? `.${formattedValue.split('.')[1]}` : ''}
                        </h5>
                    </>
                )}
            </div>

            <p className="text-base">every month</p>
        </div>
    )
}
