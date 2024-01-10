import type { ColumnDef, Row, ExpandedState } from '@tanstack/react-table'
import type { SharedType } from '@maybe-finance/shared'
import { Fragment, useMemo, useState } from 'react'
import { Prisma } from '@prisma/client'
import cn from 'classnames'
import { RiArrowDownSLine } from 'react-icons/ri'
import {
    useReactTable,
    getCoreRowModel,
    getExpandedRowModel,
    flexRender,
} from '@tanstack/react-table'
import { NumberUtil } from '@maybe-finance/shared'
import { LoadingPlaceholder } from '@maybe-finance/design-system'
import { BreakdownTableIcon } from './BreakdownTableIcon'
import { BrowserUtil } from '@maybe-finance/client/shared'

interface NetWorthBreakdownTableProps {
    isLoading: boolean
    rollup?: SharedType.AccountRollup[0]
}

type RowData =
    | SharedType.AccountRollup[0]['items'][0]
    | SharedType.AccountRollup[0]['items'][0]['items'][0]

export function NetWorthBreakdownTable({ isLoading, rollup }: NetWorthBreakdownTableProps) {
    const getLastBalance = (row: Row<RowData>) =>
        row.original?.balances.data[row.original.balances.data.length - 1]

    const getItems = (row: Row<RowData>) =>
        row.original && 'items' in row.original ? row.original.items : null

    const columns = useMemo<ColumnDef<RowData>[]>(
        () => [
            {
                id: 'type',
                header: 'Type',
                cell: ({ row }) => {
                    const items = getItems(row)
                    return (
                        <div className="w-full h-full flex gap-4 text-base">
                            {'key' in row.original! && (
                                <BreakdownTableIcon
                                    className={BrowserUtil.getCategoryColorClassName(
                                        row.original.key
                                    )}
                                    Icon={BrowserUtil.getCategoryIcon(row.original.key)}
                                />
                            )}
                            <div>
                                <p>
                                    {'name' in row.original!
                                        ? row.original.name
                                        : row.original!.title}
                                </p>

                                <p className="text-gray-100 text-base">
                                    {items &&
                                        items.length &&
                                        `${items.length} account${items.length !== 1 ? 's' : ''}`}
                                    {'connection' in row.original! && row.original.connection && (
                                        <>
                                            {row.original.connection.name}
                                            {row.original.mask != null && (
                                                <>
                                                    &nbsp;&#183;&#183;&#183;&#183;{' '}
                                                    {row.original.mask}
                                                </>
                                            )}
                                        </>
                                    )}
                                </p>
                            </div>
                        </div>
                    )
                },
            },
            {
                id: 'allocation',
                header: 'Allocation',
                cell: ({ row }) => {
                    const lastBalance = getLastBalance(row)!
                    return (
                        <div className="text-base">
                            <p className="font-medium">
                                {NumberUtil.format(lastBalance.rollupPct, 'percent', {
                                    signDisplay: 'auto',
                                    maximumFractionDigits: 2,
                                })}
                            </p>
                            {'name' in row.original! && (
                                <p className="font-normal text-gray-100">
                                    {NumberUtil.format(lastBalance.totalPct, 'percent', {
                                        signDisplay: 'auto',
                                        maximumFractionDigits: 2,
                                    })}{' '}
                                    of total
                                </p>
                            )}
                        </div>
                    )
                },
            },
            {
                id: 'amount',
                header: 'Amount',
                cell: ({ row }) => (
                    <p className="text-base font-medium">
                        {NumberUtil.format(getLastBalance(row)!.balance, 'currency', {
                            minimumFractionDigits: 0,
                            maximumFractionDigits: 0,
                        })}
                    </p>
                ),
            },
            {
                id: 'actions',
                header: '',
                cell: ({ row }) =>
                    row.getCanExpand() && (
                        <div className="flex items-center justify-end">
                            <RiArrowDownSLine
                                className={cn(
                                    'w-6 h-6 ml-2 mr-1 transition-transform',
                                    row.getIsExpanded() && 'transform scale-y-[-1]'
                                )}
                            />
                        </div>
                    ),
            },
        ],
        []
    )

    const data = useMemo<RowData[]>(
        () =>
            isLoading
                ? [
                      {
                          key: 'cash',
                          title: '',
                          items: [],
                          balances: {
                              interval: 'days',
                              start: '',
                              end: '',
                              data: [
                                  {
                                      date: '',
                                      balance: new Prisma.Decimal(1),
                                      rollupPct: new Prisma.Decimal(1),
                                      totalPct: new Prisma.Decimal(1),
                                  },
                              ],
                          },
                      },
                  ]
                : rollup?.items ?? [],
        [isLoading, rollup]
    )

    const [expanded, setExpanded] = useState<ExpandedState>({})

    const table = useReactTable({
        data,
        columns,
        state: {
            expanded,
        },
        onExpandedChange: setExpanded,
        getCoreRowModel: getCoreRowModel(),
        getExpandedRowModel: getExpandedRowModel(),
        getSubRows: (d) => ('items' in d ? d.items : []),
    })

    const rows = table.getRowModel().rows

    return (
        <LoadingPlaceholder isLoading={isLoading}>
            <table
                className={cn(
                    'min-w-full border-collapse grid',
                    'grid-cols-[2fr,1fr,1fr,1fr]', // horizontal overflow
                    'custom-gray-scroll'
                )}
            >
                <thead className="contents">
                    {table.getHeaderGroups().map((headerGroup) => (
                        <tr key={headerGroup.id} className="contents">
                            {headerGroup.headers.map((header) => (
                                <th
                                    key={header.id}
                                    colSpan={header.colSpan}
                                    className="text-sm font-medium text-gray-100 self-center first:text-left text-right pb-3 first:pl-4 last:pr-4"
                                >
                                    {!header.isPlaceholder &&
                                        flexRender(
                                            header.column.columnDef.header,
                                            header.getContext()
                                        )}
                                </th>
                            ))}
                        </tr>
                    ))}
                </thead>
                <tbody className="contents">
                    {rows.map((row, rowIndex) => {
                        const isLastChildRow =
                            row.depth > 0 &&
                            (rowIndex === rows.length - 1 || rows[rowIndex + 1].depth === 0)

                        const isParentRowNext =
                            rowIndex < rows.length - 1 && rows[rowIndex + 1].depth === 0

                        return (
                            <Fragment key={row.id}>
                                <tr
                                    className="contents group transition"
                                    role={row.getCanExpand() ? 'button' : undefined}
                                    onClick={
                                        row.getCanExpand()
                                            ? row.getToggleExpandedHandler()
                                            : undefined
                                    }
                                >
                                    {row.getVisibleCells().map((cell) => (
                                        <td
                                            key={cell.id}
                                            className={cn(
                                                'group truncate p-0 font-normal text-right first:text-left first:pl-4 last:pr-4',
                                                'group-hover:bg-gray-800 transition',
                                                row.getIsExpanded()
                                                    ? 'bg-gray-800 first:rounded-tl-lg last:rounded-tr-lg'
                                                    : row.depth === 0 &&
                                                          'first:rounded-l-lg last:rounded-r-lg',
                                                row.depth > 0
                                                    ? 'first:pl-4 py-0 bg-gray-800'
                                                    : 'py-4'
                                            )}
                                        >
                                            <div
                                                className={cn(
                                                    'w-full h-full',
                                                    row.depth > 0 && [
                                                        'py-4 bg-gray-700 group-first:pl-4 group-last:pr-4',
                                                        row.index === 0 &&
                                                            'group-first:rounded-tl-lg group-last:rounded-tr-lg',
                                                        isLastChildRow &&
                                                            'group-first:rounded-bl-lg group-last:rounded-br-lg',
                                                    ]
                                                )}
                                            >
                                                {flexRender(
                                                    cell.column.columnDef.cell,
                                                    cell.getContext()
                                                )}
                                            </div>
                                        </td>
                                    ))}
                                </tr>

                                {/* Fake parent padding below last child row */}
                                {isLastChildRow && (
                                    <tr className="contents" role="presentation">
                                        <td className="col-span-4 h-4 bg-gray-800 rounded-b-lg"></td>
                                    </tr>
                                )}

                                {/* Gap between parent rows */}
                                {isParentRowNext && (
                                    <tr className="contents" role="presentation">
                                        <td className="col-span-4 h-2"></td>
                                    </tr>
                                )}
                            </Fragment>
                        )
                    })}
                </tbody>
            </table>
        </LoadingPlaceholder>
    )
}
