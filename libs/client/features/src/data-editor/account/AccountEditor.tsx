import type { ColumnDef } from '@tanstack/react-table'
import type { AccountCategory } from '@prisma/client'
import type { TableType } from '@maybe-finance/client/shared'
import type { SharedType } from '@maybe-finance/shared'

import { DataTable, EditableCell, useAccountApi } from '@maybe-finance/client/shared'
import { Tooltip } from '@maybe-finance/design-system'
import { AccountUtil } from '@maybe-finance/shared'
import { DateTime } from 'luxon'
import { useMemo, useState } from 'react'
import { RiQuestionLine } from 'react-icons/ri'
import classNames from 'classnames'
import toast from 'react-hot-toast'

export type AccountEditorProps = { className?: string }

export type AccountRow = Pick<
    SharedType.Account,
    'id' | 'name' | 'mask' | 'category' | 'startDate' | 'classification' | 'type' | 'categoryUser'
> & {
    accountConnection?: SharedType.AccountConnection
}

export function AccountEditor({ className }: AccountEditorProps) {
    const { useUpdateAccount, useAccounts } = useAccountApi()

    const updateAccountQuery = useUpdateAccount()

    const accountsQuery = useAccounts()

    const data = useMemo<AccountRow[]>(
        () => AccountUtil.flattenAccounts(accountsQuery.data),
        [accountsQuery.data]
    )

    const [autoResetPage] = useState(false)

    const columns = useMemo<ColumnDef<AccountRow>[]>(
        () => [
            {
                header: 'Institution',
                accessorFn: (row) => {
                    return row.accountConnection?.name
                        ? `${row.accountConnection.name} (${row.mask})`
                        : 'Manual'
                },
            },
            {
                header: 'Name',
                accessorKey: 'name',
                cell: EditableCell,
                meta: { type: 'string' } as TableType.ColumnMeta<AccountRow>,
                size: 200,
            },
            {
                header: 'Category',
                id: 'categoryUser',
                accessorFn: (row) => row.category,
                cell: EditableCell,
                meta: {
                    type: 'dropdown',
                    options: (row) => {
                        return AccountUtil.CATEGORY_MAP[row.original?.type ?? 'OTHER_ASSET'].map(
                            (v) => v.value
                        )
                    },
                    formatFn: (option) => AccountUtil.CATEGORIES[option as AccountCategory].plural,
                } as TableType.ColumnMeta<AccountRow>,
            },
            {
                id: 'startDate',
                accessorFn: (row) =>
                    row.startDate
                        ? DateTime.fromJSDate(row.startDate, { zone: 'utc' }).toFormat(
                              'MM / dd / yyyy'
                          )
                        : 'Enter date',
                header: () => (
                    <div className="flex items-center">
                        <p>Start date</p>
                        <Tooltip content="The date you opened the account.  This will be the first balance shown in historical graphs for this account.">
                            <span className="ml-1.5">
                                <RiQuestionLine className="w-4 h-4" />
                            </span>
                        </Tooltip>
                    </div>
                ),
                cell: EditableCell,
                meta: {
                    type: 'date',
                } as TableType.ColumnMeta<AccountRow>,
            },
        ],
        []
    )

    if (accountsQuery.isLoading) {
        return (
            <div className="mt-6">
                <p className="text-gray-50 animate-pulse">Loading accounts...</p>
            </div>
        )
    }

    if (accountsQuery.isError) {
        return (
            <div className="mt-6">
                <p className="text-gray-50">Error loading account data</p>
            </div>
        )
    }

    if (accountsQuery.data && data.length === 0) {
        return (
            <div className="mt-6">
                <p className="text-gray-50">No accounts found</p>
            </div>
        )
    }

    return (
        <div className={classNames(className)}>
            <DataTable
                columns={columns}
                data={data}
                autoResetPage={autoResetPage}
                mutateFn={(row, key, value) => {
                    if (!row.original || !row.original.id) {
                        toast.error('Something went wrong updating account')
                        return
                    }

                    updateAccountQuery.mutate({
                        id: row.original.id,
                        data: {
                            provider: undefined,
                            data: {
                                [key]: value,
                            },
                        },
                    })
                }}
            />
        </div>
    )
}
