import type { SharedType } from '@maybe-finance/shared'
import { IncomeDebtBlock } from './IncomeDebtBlock'
import { Button, Dialog } from '@maybe-finance/design-system'
import { useMemo, useState } from 'react'
import { useUserApi } from '@maybe-finance/client/shared'

export interface IncomeDebtDialogProps {
    isOpen: boolean
    onClose: () => void
    data: SharedType.UserInsights['debtIncome']
}

export function IncomeDebtDialog({ isOpen, onClose, data }: IncomeDebtDialogProps) {
    const [income, setIncome] = useState(data.income)
    const [debt, setDebt] = useState(data.debt)

    const isDirty = useMemo(
        () => !income.equals(data.income) || !debt.equals(data.debt),
        [income, debt, data]
    )

    const { useUpdateProfile } = useUserApi()
    const updateUser = useUpdateProfile()

    return (
        <Dialog isOpen={isOpen} onClose={onClose} size="md">
            <Dialog.Title>Edit income and debt</Dialog.Title>
            <Dialog.Content>
                <p className="text-base text-gray-50">
                    Here&apos;s your monthly income and debt repayments. We use these to see how
                    much of your income is contributing to paying off any debt.
                </p>

                <IncomeDebtBlock
                    variant="Income"
                    value={income}
                    calculatedValue={data.calculated.income}
                    onChange={setIncome}
                />
                <IncomeDebtBlock
                    variant="Debt"
                    value={debt}
                    calculatedValue={data.calculated.debt}
                    onChange={setDebt}
                />
                <Button
                    className="mt-1"
                    fullWidth
                    variant={isDirty ? 'primary' : 'secondary'}
                    disabled={!isDirty || updateUser.isLoading}
                    onClick={async () => {
                        await updateUser.mutateAsync({
                            monthlyIncomeUser: income.equals(data.calculated.income)
                                ? null
                                : income.toNumber(),
                            monthlyDebtUser: debt.equals(data.calculated.debt)
                                ? null
                                : debt.toNumber(),
                        })
                        onClose()
                    }}
                >
                    Update
                </Button>
            </Dialog.Content>
        </Dialog>
    )
}
