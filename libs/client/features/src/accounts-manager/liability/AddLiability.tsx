import {
    type CreateLiabilityFields,
    useAccountApi,
    useAccountContext,
} from '@maybe-finance/client/shared'
import { DateTime } from 'luxon'
import LiabilityForm from './LiabilityForm'

export function AddLiability({ defaultValues }: { defaultValues: Partial<CreateLiabilityFields> }) {
    const { setAccountManager } = useAccountContext()
    const { useCreateAccount } = useAccountApi()
    const createAccount = useCreateAccount()

    return (
        <LiabilityForm
            mode="create"
            defaultValues={{
                name: defaultValues.name ?? 'Manual liability',
                categoryUser: defaultValues.categoryUser ?? 'other',
                maturityDate: defaultValues.maturityDate ?? '',
                interestRate: defaultValues.interestRate ?? 5,
                interestType: defaultValues.interestType ?? 'fixed',
                loanType: defaultValues.loanType ?? 'mortgage',
                startDate: null,
                currentBalance: null,
                originalBalance: null,
            }}
            onSubmit={async ({
                categoryUser,
                name,
                currentBalance,
                startDate,
                originalBalance,
                maturityDate,
                interestRate,
                interestType,
                loanType,
            }) => {
                switch (categoryUser) {
                    case 'loan':
                        await createAccount.mutateAsync({
                            name,
                            type: 'LOAN',
                            categoryUser: 'loan',
                            currentBalance,
                            startDate,
                            loanUser: {
                                originationDate: startDate,
                                originationPrincipal: originalBalance,
                                maturityDate,
                                interestRate: {
                                    type: interestType,
                                    rate:
                                        interestType === 'fixed' ? interestRate! / 100 : undefined,
                                },
                                loanDetail: {
                                    type: loanType,
                                },
                            },
                        })
                        break
                    default:
                        await createAccount.mutateAsync({
                            type: categoryUser === 'credit' ? 'CREDIT' : 'OTHER_LIABILITY',
                            categoryUser,
                            name,
                            startDate,
                            valuations: {
                                originalBalance,
                                currentBalance,
                                currentDate: DateTime.now().toISODate(),
                            },
                        })
                }

                setAccountManager({ view: 'idle' })
            }}
        />
    )
}
