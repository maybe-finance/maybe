import type { ReactNode } from 'react'
import type { Account } from '@prisma/client'
import type { SharedType } from '@maybe-finance/shared'
import type { SelectableDateRange, SelectableRangeKeys } from '@maybe-finance/design-system'

import { AccountMenu, PageTitle } from '@maybe-finance/client/features'
import { TSeries } from '@maybe-finance/client/shared'
import { DatePickerRange, getRangeDescription } from '@maybe-finance/design-system'
import { NumberUtil } from '@maybe-finance/shared'
import { DateTime } from 'luxon'
import { useMemo } from 'react'

export type DefaultViewProps = {
    account?: SharedType.AccountDetail
    balances?: SharedType.AccountBalanceResponse
    dateRange: SharedType.DateRange
    onDateChange: (range: SharedType.DateRange) => void
    getContent: (accountId: Account['id']) => ReactNode
    isLoading: boolean
    isError: boolean
    selectableDateRanges?: Array<SelectableDateRange | SelectableRangeKeys>
}

export default function DefaultView({
    account,
    balances,
    dateRange,
    onDateChange,
    getContent,
    isLoading,
    isError,
    selectableDateRanges,
}: DefaultViewProps) {
    const allTimeRange = useMemo(() => {
        return {
            label: 'All',
            labelShort: 'All',
            start: balances?.minDate ?? DateTime.now().minus({ years: 2 }).toISODate(),
            end: DateTime.now().toISODate(),
        }
    }, [balances])

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
                    selectableRanges={
                        selectableDateRanges
                            ? [...selectableDateRanges, allTimeRange]
                            : [
                                  'last-30-days',
                                  'last-6-months',
                                  'last-365-days',
                                  'last-3-years',
                                  allTimeRange,
                              ]
                    }
                />
            </div>

            <div className="h-96">
                <TSeries.Chart
                    id="investment-chart"
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
                            negative: account?.classification === 'liability',
                        },
                    ]}
                >
                    <TSeries.Line seriesKey="balances" />
                </TSeries.Chart>
            </div>

            {account && <div>{getContent(account.id)}</div>}
        </div>
    )
}
