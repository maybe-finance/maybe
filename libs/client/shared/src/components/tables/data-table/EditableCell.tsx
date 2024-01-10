import type { TableMeta, ColumnMeta, CellProps } from './types'
import { useMemo } from 'react'
import { EditableStringCell } from './EditableStringCell'
import { EditableDateCell } from './EditableDateCell'
import { EditableDropdownCell } from './EditableDropdownCell'
import { EditableBooleanCell } from './EditableBooleanCell'

export function EditableCell({ table, row, column, getValue }: CellProps) {
    const tableMeta = useMemo(() => table.options.meta as TableMeta, [table])
    const columnMeta = useMemo(() => column.columnDef.meta as ColumnMeta, [column])

    switch (columnMeta?.type) {
        case 'string': {
            return (
                <EditableStringCell
                    initialValue={getValue()}
                    onSubmit={(value) => tableMeta.mutateFn(row, column.id, value)}
                />
            )
        }
        case 'date': {
            return (
                <EditableDateCell
                    initialValue={getValue()}
                    onSubmit={(value) => tableMeta.mutateFn(row, column.id, value)}
                />
            )
        }
        case 'dropdown': {
            return (
                <EditableDropdownCell
                    initialValue={getValue()}
                    options={
                        Array.isArray(columnMeta.options)
                            ? columnMeta.options
                            : columnMeta.options(row)
                    }
                    formatFn={columnMeta.formatFn}
                    onSubmit={(value) => tableMeta.mutateFn(row, column.id, value)}
                />
            )
        }
        case 'boolean':
            return (
                <EditableBooleanCell
                    initialValue={getValue()}
                    onSubmit={(value) => tableMeta.mutateFn(row, column.id, value)}
                />
            )
        default: {
            throw new Error('Invalid editable cell configuration')
        }
    }
}
