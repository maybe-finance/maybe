import type { SharedType } from '@maybe-finance/shared'
import type { HoldingRowData } from './HoldingsTable'
import { useMemo } from 'react'
import { useAccountApi, useUserAccountContext, InfiniteScroll } from '@maybe-finance/client/shared'
import { LoadingSpinner } from '@maybe-finance/design-system'
import { HoldingsTable } from './HoldingsTable'

interface HoldingListProps {
    accountId: number
}

export function HoldingList({ accountId }: HoldingListProps) {
    const { isReady } = useUserAccountContext()

    const { useAccountHoldings } = useAccountApi()

    const accountHoldingsQuery = useAccountHoldings(
        { id: accountId },
        { enabled: !!accountId && isReady }
    )

    const data = useMemo<HoldingRowData[]>(() => {
        if (!accountHoldingsQuery.isSuccess) return []

        const mapHolding = (holding: SharedType.AccountHolding) =>
            ({
                holdingId: holding.id,
                securityId: holding.securityId,
                symbol: holding.symbol,
                name: holding.name ?? 'Holding',
                costBasis: holding.costBasis,
                costBasisUser: holding.costBasisUser,
                costBasisProvider: holding.costBasisProvider,
                price: holding.price,
                value: holding.value,
                quantity: holding.quantity,
                sharesPerContract: holding.sharesPerContract,
                returnTotal: holding.trend.total,
                returnToday: holding.trend.today,
                excluded: holding.excluded,
                holding,
            } as HoldingRowData)

        return accountHoldingsQuery.data.pages.flatMap((p) => p.holdings).map((h) => mapHolding(h))
    }, [accountHoldingsQuery])

    return (
        <div className="w-[calc(100%+2rem)] transform -translate-x-4 overflow-x-auto pb-8 custom-gray-scroll">
            <InfiniteScroll
                getScrollParent={() => document.getElementById('mainScrollArea')}
                useWindow={false}
                initialLoad={false}
                loadMore={() => accountHoldingsQuery.fetchNextPage()}
                hasMore={accountHoldingsQuery.hasNextPage}
            >
                {accountHoldingsQuery.isSuccess &&
                    (data.length ? (
                        <HoldingsTable data={data} />
                    ) : (
                        <div className="text-base text-gray-100">No holdings found</div>
                    ))}
            </InfiniteScroll>
            {(accountHoldingsQuery.isLoading || accountHoldingsQuery.isFetchingNextPage) && (
                <div className="flex items-center justify-center py-4">
                    <LoadingSpinner variant="secondary" />
                </div>
            )}
        </div>
    )
}
