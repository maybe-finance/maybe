import { DateUtil, type SharedType } from '@maybe-finance/shared'
import { useAccountApi, useAccountContext } from '@maybe-finance/client/shared'
import LiabilityForm from './LiabilityForm'
import { DateTime } from 'luxon'

export function EditLiability({ account }: { account: SharedType.AccountDetail }) {
    const { setAccountManager } = useAccountContext()

    const { useUpdateAccount } = useAccountApi()
    const updateAccount = useUpdateAccount()

    const defaultLoanValues = {
        maturityDate: account.loan?.maturityDate ?? '',
        interestRate:
            account.loan?.interestRate.type === 'fixed'
                ? account.loan.interestRate.rate
                    ? account.loan.interestRate.rate * 100
                    : null
                : null,
        loanType: account.loan?.loanDetail.type ?? null,
        interestType: account.loan?.interestRate.type ?? null,
        originalBalance: account.loan?.originationPrincipal ?? null,
        currentBalance: account.currentBalance?.toNumber() ?? null,
        startDate: DateUtil.dateTransform(account.startDate),
    }

    return (
        <LiabilityForm
            mode="update"
            accountType={account.type}
            defaultValues={{
                name: account.name,
                categoryUser: account.category,
                ...defaultLoanValues,
            }}
            onSubmit={async ({
                name,
                categoryUser,
                maturityDate,
                originalBalance,
                currentBalance,
                interestType,
                loanType,
                interestRate,
                startDate,
            }) => {
                switch (categoryUser) {
                    case 'loan': {
                        await updateAccount.mutateAsync({
                            id: account.id,
                            data: {
                                provider: account.provider,
                                data: {
                                    type: 'LOAN',
                                    name,
                                    categoryUser,
                                    currentBalance,
                                    startDate,
                                    loanUser: {
                                        originationDate: startDate,
                                        originationPrincipal: originalBalance,
                                        maturityDate,
                                        interestRate: {
                                            type: interestType,
                                            rate:
                                                interestType === 'fixed'
                                                    ? interestRate! / 100
                                                    : undefined,
                                        },
                                        loanDetail: { type: loanType },
                                    },
                                },
                            },
                        })
                        break
                    }
                    default: {
                        await updateAccount.mutateAsync({
                            id: account.id,
                            data: {
                                provider: account.provider,
                                data: {
                                    type: categoryUser === 'credit' ? 'CREDIT' : 'OTHER_LIABILITY',
                                    categoryUser,
                                    name,
                                },
                            },
                        })
                    }
                }

                setAccountManager({ view: 'idle' })
            }}
        />
    )
}
