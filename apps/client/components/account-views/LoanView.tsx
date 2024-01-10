import type { SharedType } from '@maybe-finance/shared'
import { AccountMenu, LoanDetail, PageTitle, TransactionList } from '@maybe-finance/client/features'
import { TSeries, useAccountContext } from '@maybe-finance/client/shared'
import { Button, DatePickerRange, getRangeDescription } from '@maybe-finance/design-system'
import { NumberUtil } from '@maybe-finance/shared'
import { DateTime } from 'luxon'
import { useMemo, useEffect, useState } from 'react'

export type LoanViewProps = {
    account?: SharedType.AccountDetail
    balances?: SharedType.AccountBalanceResponse
    dateRange: SharedType.DateRange
    onDateChange: (range: SharedType.DateRange) => void
    isLoading: boolean
    isError: boolean
}

export default function LoanView({
    account,
    balances,
    dateRange,
    onDateChange,
    isLoading,
    isError,
}: LoanViewProps) {
    const { editAccount } = useAccountContext()

    const [showOverlay, setShowOverlay] = useState(false)

    const allTimeRange = useMemo(() => {
        return {
            label: 'All',
            labelShort: 'All',
            start: balances?.minDate ?? DateTime.now().minus({ years: 2 }).toISODate(),
            end: DateTime.now().toISODate(),
        }
    }, [balances])

    useEffect(() => {
        const loanValid = ({ loan }: SharedType.AccountDetail) => {
            return (
                loan &&
                loan.originationDate &&
                loan.originationPrincipal &&
                loan.maturityDate &&
                loan.interestRate &&
                loan.loanDetail
            )
        }

        if (account && !loanValid(account)) {
            setShowOverlay(true)
        } else {
            setShowOverlay(false)
        }
    }, [account, editAccount])

    return (
        <div className="space-y-5">
            <div className="flex justify-between">
                <PageTitle
                    isLoading={isLoading}
                    title={account?.name}
                    value={NumberUtil.format(balances?.today?.balance, 'currency')}
                    trend={balances?.trend}
                    trendLabel={getRangeDescription(dateRange, balances?.minDate)}
                    trendNegative={account?.classification === 'liability'}
                />
                <AccountMenu account={account} />
            </div>

            <div className="flex justify-end">
                <DatePickerRange
                    variant="tabs-custom"
                    minDate={balances?.minDate}
                    maxDate={DateTime.now().toISODate()}
                    value={dateRange}
                    onChange={onDateChange}
                    selectableRanges={[
                        'last-30-days',
                        'last-6-months',
                        'last-365-days',
                        'last-3-years',
                        allTimeRange,
                    ]}
                />
            </div>

            <div className="h-96">
                <TSeries.Chart
                    id="loan-chart"
                    isLoading={isLoading}
                    isError={isError}
                    dateRange={dateRange}
                    interval={balances?.series.interval}
                    data={balances?.series.data.map((v) => ({
                        date: v.date,
                        values: { balance: v.balance },
                    }))}
                    series={[
                        {
                            key: 'balances',
                            accessorFn: (d) => d.values.balance?.toNumber(),
                            negative: true,
                        },
                    ]}
                    renderOverlay={
                        showOverlay && account
                            ? () => (
                                  <>
                                      <h3 className="mb-2">Chart unavailable</h3>
                                      <div className="max-w-screen-xs">
                                          <p className="text-base text-gray-50 max-w-[450px]">
                                              Please provide us with more details for this account
                                              so that we can build your chart with accurate values.
                                          </p>
                                      </div>
                                      <Button onClick={() => editAccount(account)} className="mt-4">
                                          Add loan terms
                                      </Button>
                                  </>
                              )
                            : undefined
                    }
                >
                    <TSeries.Line seriesKey="balances" />
                </TSeries.Chart>
            </div>

            {account && (
                <div>
                    <LoanDetail account={account} showComingSoon={!account.transactions.length} />
                    {account.transactions.length > 0 && (
                        <div className="mt-8">
                            <h5 className="uppercase mb-6">Payments</h5>
                            <TransactionList accountId={account.id} />
                        </div>
                    )}
                </div>
            )}
        </div>
    )
}
