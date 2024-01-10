import type { SharedType } from '@maybe-finance/shared'
import { useAccountContext, BrowserUtil } from '@maybe-finance/client/shared'
import { NumberUtil } from '@maybe-finance/shared'
import { DateTime } from 'luxon'
import toast from 'react-hot-toast'
import { RiAddLine, RiPencilLine } from 'react-icons/ri'
import { LoanCard } from './LoanCard'

export type LoanDetailProps = {
    account: SharedType.AccountDetail
    showComingSoon?: boolean
}

export function LoanDetail({ account, showComingSoon = false }: LoanDetailProps) {
    const { loan } = account

    const { editAccount } = useAccountContext()

    return (
        <div data-testid="loan-detail-cards">
            <div className="flex justify-between items-center mb-4">
                <h5 className="uppercase">Loan Overview</h5>
                <button
                    className="flex items-center px-2 py-1 font-medium bg-gray-500 rounded hover:bg-gray-400"
                    onClick={() => {
                        if (!account) {
                            toast.error('Unable to edit loan')
                            return
                        }

                        editAccount(account)
                    }}
                >
                    {!loan ? (
                        <>
                            <RiAddLine className="w-5 h-5 text-gray-50" />
                            <span className="ml-2 text-base">Add terms</span>
                        </>
                    ) : (
                        <>
                            <RiPencilLine className="w-5 h-5 text-gray-50" />
                            <span className="ml-2 text-base">Edit terms</span>
                        </>
                    )}
                </button>
            </div>

            <div className="relative grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
                <LoanCard
                    isLoading={false}
                    title="Loan amount"
                    info="The contractual starting balance for this loan"
                    detail={
                        loan
                            ? {
                                  metricValue: NumberUtil.format(
                                      loan.originationPrincipal,
                                      'currency'
                                  ),
                                  metricDetail: `Originated on ${DateTime.fromISO(
                                      loan.originationDate ?? ''
                                  ).toFormat('MMM d, yyyy')}`,
                              }
                            : undefined
                    }
                />

                <LoanCard
                    isLoading={false}
                    title="Remaining balance"
                    info="The remaining balance on this loan"
                    detail={
                        loan && loan.originationPrincipal && account.currentBalance
                            ? {
                                  metricValue: NumberUtil.format(
                                      account.currentBalance.toNumber(),
                                      'currency'
                                  ),
                                  metricDetail: `${NumberUtil.format(
                                      loan.originationPrincipal - account.currentBalance.toNumber(),
                                      'currency'
                                  )} principal already paid`,
                              }
                            : undefined
                    }
                />

                <LoanCard
                    isLoading={false}
                    title="Loan terms"
                    info="The details of your loan contract"
                    detail={
                        loan && loan.originationDate && loan.maturityDate && loan.interestRate
                            ? {
                                  metricValue: BrowserUtil.formatLoanTerm(loan),
                                  metricDetail:
                                      loan.interestRate.type !== 'fixed'
                                          ? 'Variable rate loan'
                                          : loan.interestRate.rate
                                          ? `Fixed rate, ${NumberUtil.format(
                                                loan.interestRate.rate,
                                                'percent',
                                                {
                                                    signDisplay: 'auto',
                                                    minimumFractionDigits: 2,
                                                    maximumFractionDigits: 2,
                                                }
                                            )} interest annually`
                                          : 'Fixed rate loan',
                              }
                            : undefined
                    }
                />

                {!loan && (
                    <div className="absolute inset-0 flex flex-col items-center justify-center w-full h-full text-center bg-black rounded bg-opacity-90 backdrop-blur-sm">
                        <div className="text-gray-50 text-base max-w-[400px]">
                            <p>This is where your loan details will show. </p>
                            <p>
                                <button
                                    className="text-white hover:text-opacity-90"
                                    onClick={() => editAccount(account)}
                                >
                                    Add loan terms
                                </button>{' '}
                                to see both the chart and these metrics.
                            </p>
                        </div>
                    </div>
                )}
            </div>

            {showComingSoon && (
                <div className="p-10 my-10">
                    <div className="flex flex-col items-center max-w-lg mx-auto text-center">
                        <img alt="Maybe" width={74} height={60} src="/assets/maybe-gray.svg" />
                        <h4 className="mt-3 mb-2">
                            This view is kinda empty, but there&apos;s a reason for that
                        </h4>
                        <p className="text-base text-gray-50">
                            We are constantly reviewing and prioritizing your feedback, and we know
                            you're itching to see some more details about your loan! Hold tight,
                            this feature is on our roadmap and we're getting to it as quickly as we
                            can!
                        </p>
                    </div>
                </div>
            )}
        </div>
    )
}
