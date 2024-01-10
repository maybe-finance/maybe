import type { CellProps } from './types'

export function DefaultCell({ getValue }: CellProps) {
    return (
        <div className="p-2 text-base text-gray-50">
            <p>{getValue()}</p>
        </div>
    )
}
