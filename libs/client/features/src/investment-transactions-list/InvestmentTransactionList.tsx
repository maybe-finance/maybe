import { useMemo } from 'react'
import { LoadingSpinner } from '@maybe-finance/design-system'
import { DateTime } from 'luxon'
import { useAccountApi, useUserAccountContext, InfiniteScroll } from '@maybe-finance/client/shared'
import groupBy from 'lodash/groupBy'
import { InvestmentTransactionListItem } from './InvestmentTransactionListItem'
import type { SharedType } from '@maybe-finance/shared'

export function InvestmentTransactionList({
    accountId,
    filter,
}: {
    accountId: number
    filter?: { category?: SharedType.InvestmentTransactionCategory }
}) {
    const { isReady } = useUserAccountContext()

    const { useAccountInvestmentTransactions } = useAccountApi()

    const accountTransactionsQuery = useAccountInvestmentTransactions(
        { id: accountId, ...filter },
        { enabled: !!accountId && isReady, keepPreviousData: true }
    )

    const groupedTransactions = useMemo(() => {
        if (!accountTransactionsQuery.data?.pages) return {}

        // Flatten, normalize, and group transactions by date
        const transactions = accountTransactionsQuery.data.pages
            .flatMap((page) => page.investmentTransactions)
            .map((txn) => ({
                ...txn,
                dateFormatted: DateTime.fromJSDate(txn.date, { zone: 'utc' }).toFormat(
                    'MMM d yyyy'
                ),
                // Flip amount values to be more user-friendly (positive inflow, negative outflow)
                amount: txn.amount.negated(),
            }))

        return groupBy(transactions, (t) => t.dateFormatted)
    }, [accountTransactionsQuery.data])

    return (
        <div className="relative w-full pb-4 overflow-x-auto overflow-y-hidden custom-gray-scroll">
            {accountTransactionsQuery?.data && (
                <>
                    {Object.keys(groupedTransactions).length ? (
                        <InfiniteScroll
                            getScrollParent={() => document.getElementById('mainScrollArea')}
                            useWindow={false}
                            initialLoad={false}
                            loadMore={() => accountTransactionsQuery.fetchNextPage()}
                            hasMore={accountTransactionsQuery.hasNextPage}
                        >
                            <div className="text-base">
                                {[...Object.keys(groupedTransactions)].map((group) => (
                                    <div key={group}>
                                        <div className="font-medium text-gray-100">{group}</div>
                                        <div className="mt-4 mb-6 rounded-xl bg-gray-800 overflow-hidden">
                                            <table className="w-full">
                                                <tbody>
                                                    {groupedTransactions[group].map(
                                                        (transaction) => (
                                                            <InvestmentTransactionListItem
                                                                transaction={transaction}
                                                                key={transaction.id}
                                                            />
                                                        )
                                                    )}
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </InfiniteScroll>
                    ) : (
                        <div className="text-base text-gray-100">No transactions found</div>
                    )}

                    {accountTransactionsQuery.isPreviousData &&
                        Object.keys(groupedTransactions).length && (
                            <div className="flex justify-center absolute top-0 left-0 w-full h-full bg-black bg-opacity-80">
                                <LoadingSpinner variant="secondary" className="mt-12" />
                            </div>
                        )}
                </>
            )}
            {((accountTransactionsQuery.isLoading && !accountTransactionsQuery?.data) ||
                accountTransactionsQuery.isFetchingNextPage) && (
                <div className="flex items-center justify-center pt-4 pb-32">
                    <LoadingSpinner variant="secondary" />
                </div>
            )}
        </div>
    )
}
