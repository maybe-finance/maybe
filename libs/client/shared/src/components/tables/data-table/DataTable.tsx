import type { TableMeta } from './types'
import type { ColumnDef, PaginationState, OnChangeFn } from '@tanstack/react-table'
import { useMemo } from 'react'
import { getCoreRowModel, useReactTable, flexRender } from '@tanstack/react-table'
import { DefaultCell } from './DefaultCell'
import { Button } from '@maybe-finance/design-system'
import { RiArrowLeftLine, RiArrowRightLine } from 'react-icons/ri'

export interface DataTableProps {
    data: any[]
    columns: Array<ColumnDef<any>>
    mutateFn: TableMeta<any>['mutateFn']
    autoResetPage: boolean
    defaultColumn?: Partial<ColumnDef<any>>
    paginationOpts?: {
        pagination: PaginationState
        pageCount: number
        onChange: OnChangeFn<PaginationState>
    }
}

export function DataTable({
    columns,
    data,
    mutateFn,
    defaultColumn,
    paginationOpts,
}: DataTableProps) {
    // Properties defined here will be shared across all columns
    const defaultColumnInternal = useMemo<Partial<ColumnDef<any>>>(
        () => ({
            cell: DefaultCell,
            enableResizing: true,
            minSize: 175,
            ...defaultColumn,
        }),
        [defaultColumn]
    )

    const table = useReactTable({
        data,
        columns,
        defaultColumn: defaultColumnInternal,
        getCoreRowModel: getCoreRowModel(),
        meta: { mutateFn } as TableMeta<any>,
        ...(paginationOpts && {
            state: {
                pagination: paginationOpts.pagination,
            },
            manualPagination: true,
            onPaginationChange: paginationOpts.onChange,
            pageCount: paginationOpts.pageCount,
        }),
    })

    return (
        <div className="py-6 custom-gray-scroll">
            <table style={{ width: table.getCenterTotalSize() }}>
                <thead>
                    {table.getHeaderGroups().map((headerGroup) => (
                        <tr key={headerGroup.id}>
                            {headerGroup.headers.map((header) => (
                                <th
                                    key={header.id}
                                    colSpan={header.colSpan}
                                    className="text-base text-left p-2"
                                    style={{
                                        width: header.getSize(),
                                    }}
                                >
                                    {header.isPlaceholder
                                        ? null
                                        : flexRender(
                                              header.column.columnDef.header,
                                              header.getContext()
                                          )}
                                </th>
                            ))}
                        </tr>
                    ))}
                </thead>

                <tbody>
                    {table.getRowModel().rows.map((row) => (
                        <tr key={row.id} className="border-t last:border-b border-gray-700">
                            {row.getVisibleCells().map((cell) => (
                                <td
                                    key={cell.id}
                                    className="border-l last:border-r border-gray-700"
                                >
                                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                                </td>
                            ))}
                        </tr>
                    ))}
                </tbody>
            </table>

            {paginationOpts && (
                <div className="flex items-center gap-2 mt-4">
                    <Button
                        variant="link"
                        disabled={!table.getCanPreviousPage()}
                        onClick={() => table.previousPage()}
                    >
                        <RiArrowLeftLine className="mr-1" />
                        Back
                    </Button>
                    <span className="text-gray-50 font-semibold">
                        {table.getState().pagination.pageIndex + 1} / {table.getPageCount()}
                    </span>
                    <Button
                        variant="link"
                        disabled={!table.getCanNextPage()}
                        onClick={() => table.nextPage()}
                    >
                        Next
                        <RiArrowRightLine className="ml-1" />
                    </Button>
                </div>
            )}
        </div>
    )
}
