import type { ColumnDef } from '@tanstack/react-table'
import type { SharedType } from '@maybe-finance/shared'
import { useMemo } from 'react'
import Image from 'next/legacy/image'
import { useReactTable, getCoreRowModel, flexRender } from '@tanstack/react-table'
import { NumberUtil } from '@maybe-finance/shared'
import { BrowserUtil, TrendBadge, usePopoutContext } from '@maybe-finance/client/shared'
import { HoldingPopout } from './HoldingPopout'
import { RiEyeOffLine, RiQuestionLine } from 'react-icons/ri'
import { Tooltip } from '@maybe-finance/design-system'

export interface HoldingRowData {
    name: string
    price: SharedType.Decimal
    securityId: number
    costBasis: SharedType.Decimal | null
    costBasisUser: SharedType.Decimal | null
    costBasisProvider: SharedType.Decimal | null
    value: SharedType.Decimal
    quantity: SharedType.Decimal
    sharesPerContract: SharedType.Decimal | null
    returnTotal: SharedType.Trend | null
    returnToday: SharedType.Trend | null
    symbol: string | null
    holdingId?: number
    excluded: boolean
    holding: SharedType.AccountHolding
}

interface HoldingsTableProps {
    data: HoldingRowData[]
}

export function HoldingsTable({ data }: HoldingsTableProps) {
    const { open: openPopout } = usePopoutContext()

    const columns = useMemo(
        () => [
            {
                id: 'name',
                header: 'Name',
                accessorFn: (row) => row.symbol ?? row.name,
                cell: ({ row: { original: holding } }) => (
                    <div className="flex items-center space-x-4">
                        <div className="relative">
                            <div className="relative w-12 h-12 shrink-0 bg-gray-400 rounded-xl overflow-hidden">
                                <Image
                                    loader={BrowserUtil.enhancerizerLoader}
                                    src={JSON.stringify({
                                        kind: 'security',
                                        name: holding!.symbol ?? holding!.name,
                                    })}
                                    layout="fill"
                                    sizes="48px, 64px, 96px, 128px"
                                    onError={({ currentTarget }) => {
                                        // Fail gracefully and hide image
                                        currentTarget.onerror = null
                                        currentTarget.style.display = 'none'
                                    }}
                                />
                            </div>
                            {holding.excluded && (
                                <div className="absolute flex items-center justify-center -bottom-1 -right-2 w-5 h-5 box-border rounded-full border-2 border-black bg-gray-500">
                                    <RiEyeOffLine className="w-3.5 h-3.5" />
                                </div>
                            )}
                        </div>
                        <div className="min-w-0">
                            <div className="truncate">{holding!.name}</div>
                            {holding!.symbol && (
                                <div className="text-gray-100">{holding!.symbol}</div>
                            )}
                        </div>
                    </div>
                ),
            } as ColumnDef<HoldingRowData, HoldingRowData['name']>,
            {
                header: 'Price',
                accessorKey: 'price',
                cell: ({ getValue }) => (
                    <div className="font-semibold tabular-nums text-right">
                        {NumberUtil.format(getValue(), 'currency')}
                    </div>
                ),
            } as ColumnDef<HoldingRowData, HoldingRowData['price']>,
            {
                header: 'Cost',
                accessorKey: 'costBasis',
                cell: ({ getValue, row }) => {
                    return (
                        <div className="text-right">
                            <div className="font-medium tabular-nums">
                                {!row.original.costBasisProvider && '~'}
                                {NumberUtil.format(getValue(), 'currency')}
                            </div>
                            <div className="text-gray-100 flex items-center justify-end">
                                per share
                                {!row.original.costBasisProvider && (
                                    <Tooltip
                                        content={
                                            <span className="text-base text-gray-50">
                                                This value is an estimated average, due to missing
                                                data from one of our providers. You can adjust it by
                                                clicking on the holding.
                                            </span>
                                        }
                                    >
                                        <span className="ml-1.5 inline-block">
                                            <RiQuestionLine className="w-5 h-5" />
                                        </span>
                                    </Tooltip>
                                )}
                            </div>
                        </div>
                    )
                },
            } as ColumnDef<HoldingRowData, HoldingRowData['costBasis']>,
            {
                header: 'Holdings',
                accessorKey: 'quantity',
                cell: ({ getValue, row: { original: holding } }) => (
                    <div className="text-right">
                        <div className="font-medium tabular-nums">
                            {NumberUtil.format(holding!.value, 'currency')}
                        </div>
                        <div className="text-gray-100">
                            {getValue().toNumber()}{' '}
                            {holding!.sharesPerContract == null ? 'share' : 'contract'}
                            {!getValue().eq(1) && 's'}
                        </div>
                    </div>
                ),
            } as ColumnDef<HoldingRowData, HoldingRowData['quantity']>,
            {
                header: 'Daily gain',
                accessorKey: 'returnToday',
                cell: (info) => <PerformanceMetric trend={info.getValue()} />,
            } as ColumnDef<HoldingRowData, HoldingRowData['returnToday']>,
            {
                header: 'Total gain',
                accessorKey: 'returnTotal',
                cell: (info) => <PerformanceMetric trend={info.getValue()} />,
            } as ColumnDef<HoldingRowData, HoldingRowData['returnTotal']>,
        ],
        []
    )

    const table = useReactTable({
        data,
        columns,
        getCoreRowModel: getCoreRowModel(),
    })

    return (
        <table className="table-fixed min-w-full gap-x-5 text-base">
            <thead>
                {table.getHeaderGroups().map((headerGroup) => (
                    <tr key={headerGroup.id}>
                        {headerGroup.headers.map((header) => (
                            <th
                                key={header.id}
                                colSpan={header.colSpan}
                                className="px-2.5 first:pl-4 last:pr-4 whitespace-nowrap font-medium text-gray-100 text-right first:text-left"
                            >
                                {!header.isPlaceholder &&
                                    flexRender(header.column.columnDef.header, header.getContext())}
                            </th>
                        ))}
                    </tr>
                ))}
            </thead>
            <tbody>
                {table.getRowModel().rows.map((row) => (
                    <tr
                        key={row.id}
                        className="cursor-pointer hover:bg-gray-800"
                        onClick={() =>
                            openPopout(
                                <HoldingPopout
                                    key={row.id}
                                    holdingId={row.original.holding.id}
                                    securityId={row.original.holding.securityId}
                                />
                            )
                        }
                    >
                        {row.getVisibleCells().map((cell) => (
                            <td
                                key={cell.id}
                                className="px-2.5 first:pl-4 last:pr-4 py-4 first:rounded-l-lg last:rounded-r-lg whitespace-nowrap font-normal truncate"
                            >
                                {flexRender(cell.column.columnDef.cell, cell.getContext())}
                            </td>
                        ))}
                    </tr>
                ))}
            </tbody>
        </table>
    )
}

function PerformanceMetric({ trend }: { trend: SharedType.Trend | null }) {
    if (!trend) return null

    return (
        <div className="flex flex-col items-end space-y-0.5">
            <div className="font-medium tabular-nums">
                {NumberUtil.format(trend.amount, 'currency', {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                })}
            </div>
            <TrendBadge trend={trend} badgeSize="sm" />
        </div>
    )
}
