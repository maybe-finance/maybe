import type { ColumnDef, PaginationState } from '@tanstack/react-table'
import type { TableType } from '@maybe-finance/client/shared'
import type { SharedType } from '@maybe-finance/shared'

import { DataTable, EditableCell, useTransactionApi } from '@maybe-finance/client/shared'
import { NumberUtil, TransactionUtil } from '@maybe-finance/shared'
import classNames from 'classnames'
import { DateTime } from 'luxon'
import { useMemo, useState } from 'react'
import toast from 'react-hot-toast'

export type TransactionEditorProps = { className?: string }

export type TransactionRow = Pick<
    SharedType.Transaction,
    'id' | 'name' | 'category' | 'date' | 'amount' | 'excluded'
> & {
    account: SharedType.Account
}

const PAGE_SIZE = 10

export function TransactionEditor({ className }: TransactionEditorProps) {
    const [autoResetPage] = useState(true)

    const [{ pageIndex, pageSize }, setPagination] = useState<PaginationState>({
        pageIndex: 0,
        pageSize: PAGE_SIZE,
    })

    const { useTransactions, useUpdateTransaction } = useTransactionApi()

    const transactionsQuery = useTransactions({ pageSize, pageIndex }, { keepPreviousData: true })

    const updateTransactionQuery = useUpdateTransaction()

    const columns = useMemo<ColumnDef<TransactionRow>[]>(
        () => [
            {
                id: 'date',
                accessorFn: (row) =>
                    DateTime.fromJSDate(row.date, { zone: 'utc' }).toFormat('MMM dd, yyyy'),
                header: 'Date',
                minSize: 125,
                size: 125,
            },
            {
                id: 'account',
                accessorFn: (row) => row.account.name,
                header: 'Account',
            },
            {
                header: 'Name',
                accessorKey: 'name',
                size: 300,
            },
            {
                header: 'Amount',
                accessorFn: (row) => NumberUtil.format(row.amount, 'currency'),
            },
            {
                header: 'Category',
                id: 'categoryUser',
                accessorKey: 'category',
                cell: EditableCell,
                meta: {
                    type: 'dropdown',
                    options: TransactionUtil.CATEGORIES,
                } as TableType.ColumnMeta<TransactionRow>,
            },
            {
                header: 'Excluded',
                accessorKey: 'excluded',
                cell: EditableCell,
                size: 40,
                maxSize: 40,
                meta: { type: 'boolean' } as TableType.ColumnMeta<TransactionRow>,
            },
        ],
        []
    )

    if (transactionsQuery.isLoading) {
        return (
            <div className="mt-6">
                <p className="text-gray-50 animate-pulse">Loading transactions...</p>
            </div>
        )
    }

    if (transactionsQuery.isError) {
        return (
            <div className="mt-6">
                <p className="text-gray-50">Error loading transaction data</p>
            </div>
        )
    }

    if (transactionsQuery.data && transactionsQuery.data.transactions.length === 0) {
        return (
            <div className="mt-6">
                <p className="text-gray-50">No transactions found in your account</p>
            </div>
        )
    }

    return (
        <div className={classNames(className)}>
            <p className="text-gray-50 text-base">
                For more advanced transaction editing, please go to the specific account page and
                edit the transaction inline.
            </p>

            <DataTable
                columns={columns}
                data={
                    transactionsQuery.data?.transactions.map((txn) => ({
                        ...txn,
                        amount: txn.amount.negated(),
                    })) ?? []
                }
                autoResetPage={autoResetPage}
                mutateFn={(row, key, value) => {
                    if (!row.original || !row.original.id) {
                        toast.error('Something went wrong updating transaction')
                        return
                    }

                    updateTransactionQuery.mutate({
                        id: row.original.id,
                        data: {
                            [key]: value,
                        },
                    })
                }}
                paginationOpts={{
                    pagination: { pageIndex, pageSize },
                    onChange: setPagination,
                    pageCount: transactionsQuery.data?.pageCount ?? -1,
                }}
            />
        </div>
    )
}
