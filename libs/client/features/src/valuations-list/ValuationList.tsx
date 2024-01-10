import type { ValuationRowData } from './types'
import type { SharedType } from '@maybe-finance/shared'

import { useValuationApi, useUserAccountContext } from '@maybe-finance/client/shared'
import { Button } from '@maybe-finance/design-system'
import Decimal from 'decimal.js'
import sortBy from 'lodash/sortBy'
import { DateTime } from 'luxon'
import { useMemo, useState } from 'react'
import { ValuationsTable } from './ValuationsTable'

interface ValuationListProps {
    accountId: number
    negative?: boolean
}

export function ValuationList({ accountId, negative = false }: ValuationListProps) {
    const { isReady, accountSyncing } = useUserAccountContext()

    const { useAccountValuations } = useValuationApi()

    const [rowEditingIndex, setRowEditingIndex] = useState<number | undefined>(undefined)
    const [isAdding, setIsAdding] = useState(false)

    const accountValuationsQuery = useAccountValuations(
        { id: accountId },
        { enabled: !!accountId && isReady }
    )

    const data = useMemo<ValuationRowData[]>(() => {
        if (!accountValuationsQuery.isSuccess) return []

        const mapValuation = (
            valuation: SharedType.AccountValuationsResponse['valuations'][0],
            isFirst: boolean
        ): ValuationRowData => ({
            accountId: valuation.accountId,
            valuationId: valuation.id,
            date: DateTime.fromJSDate(valuation.date, { zone: 'utc' }),
            type: isFirst ? 'initial' : 'manual',
            amount: valuation.amount,
            period: valuation.trend
                ? valuation.trend.period
                : { direction: 'flat', amount: new Decimal(0), percentage: new Decimal(0) },
            total: valuation.trend
                ? valuation.trend.total
                : { direction: 'flat', amount: new Decimal(0), percentage: new Decimal(0) },
        })

        // If there is only 1 valuation, no trends should be shown
        if (accountValuationsQuery.data.valuations.length === 1 && !isAdding) {
            const valuation = accountValuationsQuery.data.valuations[0]

            return [mapValuation(valuation, true)]
        }

        const normalizedTrends: ValuationRowData[] = accountValuationsQuery.data.trends.map(
            (trend) => ({
                date: DateTime.fromISO(trend.date),
                type: 'trend',
                amount: trend.amount,
                period: trend.period,
                total: trend.total,
            })
        )

        const normalizedValuations: ValuationRowData[] = accountValuationsQuery.data.valuations.map(
            (valuation, index) => mapValuation(valuation, index === 0)
        )

        // Combines and sorts the trends and valuations by date, descending
        const combinedValuations = sortBy([...normalizedTrends, ...normalizedValuations], (val) =>
            val.date.toJSDate()
        ).reverse()

        // If the user has clicked "Add entry", insert a blank entry at the start of the array
        if (isAdding) {
            combinedValuations.unshift({
                accountId,
                amount: combinedValuations[0].amount, // set input to most recent valuation
                date: DateTime.now(),
                type: 'manual',
                period: {
                    direction: 'flat',
                    amount: new Decimal(0),
                    percentage: new Decimal(0),
                },
                total: {
                    direction: 'flat',
                    amount: new Decimal(0),
                    percentage: new Decimal(0),
                },
            })
        }

        return combinedValuations
    }, [accountValuationsQuery, isAdding, accountId])

    return (
        <div className="px-2 sm:px-0">
            <div className="flex items-center justify-between">
                <h5 className="uppercase">ACTIVITY</h5>
                <Button
                    disabled={accountSyncing(accountId)}
                    variant="secondary"
                    onClick={() => {
                        setIsAdding(true)
                        setRowEditingIndex(0)
                    }}
                >
                    Add entry
                </Button>
            </div>
            {/* 
                To achieve the CSS hover styles where an entire table row is highlighted, and expands outside
                of the table bounds, a few tweaks have been made:

                1) Table container is 16px * 2 = 32px = 2rem wider than its parent container (calc(100%+2rem))
                2) Table container is shifted -16px to the left (-translate-x-4), so it breaks out of its parent container 16px on both sides
                3) Table cells have horizontal padding of 16px to keep cell content aligned with the rest of the page (see <table></table>)

                With these settings, the content should never break out of the viewport
            */}
            <div className="w-[calc(100%+2rem)] transform -translate-x-4 mt-4 custom-gray-scroll">
                <ValuationsTable
                    data={data}
                    isAdding={isAdding}
                    rowEditingIndex={rowEditingIndex}
                    onEdit={(index) => {
                        setIsAdding(false)
                        setRowEditingIndex(index)
                    }}
                    negative={negative}
                />
            </div>
        </div>
    )
}
