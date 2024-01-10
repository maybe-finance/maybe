import { useEffect, useState } from 'react'

export type EditableBooleanCellProps = {
    initialValue: boolean
    onSubmit(value: boolean): void
}

export function EditableBooleanCell({ initialValue, onSubmit }: EditableBooleanCellProps) {
    const [value, setValue] = useState(initialValue)

    useEffect(() => {
        setValue(initialValue)
    }, [initialValue])

    return (
        <div className="flex items-center justify-center">
            <input
                type="checkbox"
                className="h-5 w-5 bg-transparent border-gray-200 text-gray-200 rounded focus:ring-1 focus:ring-gray-200 focus:ring-offset-black"
                value="checked"
                checked={value}
                onChange={(e) => onSubmit(e.currentTarget.checked)}
            />
        </div>
    )
}
