import type { Cell, Column, Row, Table } from '@tanstack/react-table'

export type TableMeta<TData extends {} = any> = {
    mutateFn: (row: Row<TData>, key: string, value: any) => void
}

export type ColumnMeta<TData extends {} = any> =
    | {
          type: 'string' | 'date' | 'boolean'
      }
    | {
          type: 'dropdown'
          options: string[] | ((row: Row<TData>) => string[])
          formatFn?: (option: string) => string
      }
    | undefined

export type CellProps = {
    table: Table<any>
    row: Row<any>
    column: Column<any, any>
    cell: Cell<any, any>
    getValue: () => any
}
