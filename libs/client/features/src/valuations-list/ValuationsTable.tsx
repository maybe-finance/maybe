import type { ColumnDef } from '@tanstack/react-table'
import type { ValuationRowData } from './types'
import { useMemo } from 'react'
import { flexRender, getCoreRowModel, useReactTable } from '@tanstack/react-table'
import { NumberUtil } from '@maybe-finance/shared'
import { ValuationsTableForm } from './ValuationsTableForm'
import { PerformanceMetric } from './PerformanceMetric'
import { ValuationsDateCell } from './ValuationsDateCell'

interface ValuationsTableProps {
    data: ValuationRowData[]
    isAdding: boolean
    rowEditingIndex?: number
    onEdit(rowIndex?: number): void
    negative?: boolean
}

export function ValuationsTable({ data, rowEditingIndex, onEdit, negative }: ValuationsTableProps) {
    const columns = useMemo(
        () => [
            {
                id: 'date',
                header: 'Date',
                cell: ({ row }) => <ValuationsDateCell row={row} onEdit={onEdit} />,
            } as ColumnDef<ValuationRowData, ValuationRowData['date']>,
            {
                header: 'Value',
                accessorKey: 'amount',
                cell: ({ getValue }) => (
                    <p className="text-base font-medium min-w-24">
                        {NumberUtil.format(getValue(), 'currency')}
                    </p>
                ),
            } as ColumnDef<ValuationRowData, ValuationRowData['amount']>,
            {
                header: 'Change',
                accessorKey: 'period',
                cell: ({ row, getValue }) => (
                    <PerformanceMetric
                        trend={getValue()}
                        isInitial={row.original?.type === 'initial'}
                        negative={negative}
                    />
                ),
            } as ColumnDef<ValuationRowData, ValuationRowData['period']>,
            {
                header: 'Return',
                accessorKey: 'total',
                cell: ({ row, getValue }) => (
                    <PerformanceMetric
                        trend={getValue()}
                        isInitial={row.original?.type === 'initial'}
                        negative={negative}
                    />
                ),
            } as ColumnDef<ValuationRowData, ValuationRowData['total']>,
        ],
        [onEdit, negative]
    )

    const table = useReactTable<ValuationRowData>({
        data,
        columns,
        getCoreRowModel: getCoreRowModel(),
    })

    return (
        <table
            className="min-w-full text-base grid items-stretch"
            style={{
                gridTemplateColumns: `minmax(300px, 3fr) repeat(2, minmax(200px, 2fr)) minmax(180px, 1fr)`,
            }}
        >
            <thead className="contents">
                {table.getHeaderGroups().map((headerGroup) => (
                    <tr key={headerGroup.id} className="contents">
                        {headerGroup.headers.map((header) => (
                            <th
                                key={header.id}
                                className="py-3 first:pl-4 last:pr-4 whitespace-nowrap font-medium text-gray-100 text-right first:text-left"
                            >
                                {!header.isPlaceholder &&
                                    flexRender(header.column.columnDef.header, header.getContext())}
                            </th>
                        ))}
                    </tr>
                ))}
            </thead>
            <tbody className="contents">
                {table.getRowModel().rows.map((row) => {
                    return row.index === rowEditingIndex ? (
                        <tr key={row.id} className="contents">
                            <ValuationsTableForm row={row} onEdit={onEdit} />
                        </tr>
                    ) : (
                        <tr key={row.id} className="contents group">
                            {row.getVisibleCells().map((cell) => (
                                <td
                                    key={cell.id}
                                    className="py-4 first:pl-4 last:pr-4 whitespace-nowrap font-normal truncate text-right first:text-left group-hover:bg-gray-700 first:rounded-l-lg last:rounded-r-lg"
                                >
                                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                                </td>
                            ))}
                        </tr>
                    )
                })}
            </tbody>
        </table>
    )
}
