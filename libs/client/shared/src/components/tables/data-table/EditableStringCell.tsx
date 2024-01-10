import { useEffect, useState } from 'react'
import { RiCheckLine, RiCloseLine } from 'react-icons/ri'

export type EditableStringCellProps = {
    initialValue: string
    onSubmit: (value: string) => void
}

export function EditableStringCell({ initialValue, onSubmit }: EditableStringCellProps) {
    const [value, setValue] = useState(initialValue)

    useEffect(() => {
        setValue(initialValue)
    }, [initialValue])

    return (
        <div className="group text-white-300 focus-within:bg-gray-800">
            <div className="flex items-center">
                <input
                    value={value}
                    type="text"
                    className="text-base bg-transparent w-full border-0 focus:ring-0"
                    onChange={(e) => setValue(e.target.value)}
                />

                <div className="hidden pr-1 group-focus-within:flex">
                    <button
                        type="button"
                        onClick={(e) => {
                            setValue(initialValue)
                            e.currentTarget.blur()
                        }}
                    >
                        <RiCloseLine className="w-5 h-5 hover:opacity-80" />
                    </button>
                    <button
                        type="button"
                        onClick={(e) => {
                            onSubmit(value)
                            e.currentTarget.blur()
                        }}
                    >
                        <RiCheckLine className="w-5 h-5 hover:opacity-80" />
                    </button>
                </div>
            </div>
        </div>
    )
}
