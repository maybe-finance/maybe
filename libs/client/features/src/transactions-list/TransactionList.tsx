import { useMemo } from 'react'
import { LoadingSpinner } from '@maybe-finance/design-system'
import { DateTime } from 'luxon'
import { useAccountApi, useUserAccountContext, InfiniteScroll } from '@maybe-finance/client/shared'
import groupBy from 'lodash/groupBy'
import { TransactionListItem } from './TransactionListItem'

export function TransactionList({ accountId }: { accountId: number }) {
    const { isReady } = useUserAccountContext()

    const { useAccountTransactions } = useAccountApi()

    const accountTransactionsQuery = useAccountTransactions(
        { id: accountId },
        { enabled: !!accountId && isReady }
    )

    const groupedTransactions = useMemo(() => {
        if (!accountTransactionsQuery.data?.pages) return {}

        // Flatten, normalize, and group transactions by date
        const transactions = accountTransactionsQuery.data.pages
            .flatMap((page) => page.transactions)
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
        <div className="pb-4">
            {accountTransactionsQuery?.data &&
                (Object.keys(groupedTransactions).length ? (
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
                                    <div className="font-medium">{group}</div>
                                    <ol className="mt-4 mb-6 rounded-xl border border-gray-500 p-4">
                                        {groupedTransactions[group].map((transaction) => (
                                            <TransactionListItem
                                                transaction={transaction}
                                                key={transaction.id}
                                            />
                                        ))}
                                    </ol>
                                </div>
                            ))}
                        </div>
                    </InfiniteScroll>
                ) : (
                    <div className="text-base text-gray-100">
                        No transactions found for the selected date range
                    </div>
                ))}
            {}
            {(accountTransactionsQuery.isLoading ||
                accountTransactionsQuery.isFetchingNextPage) && (
                <div className="flex items-center justify-center py-2">
                    <LoadingSpinner variant="secondary" />
                </div>
            )}
        </div>
    )
}
