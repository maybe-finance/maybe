import type { ReactNode } from 'react'
import classNames from 'classnames'

export interface InputHintProps {
    error?: boolean
    disabled?: boolean
    children: ReactNode
}

export default function InputHint({
    error = false,
    disabled = false,
    children,
}: InputHintProps): JSX.Element {
    return (
        <span
            className={classNames(
                'ml-1 text-sm leading-4 mt-1',
                disabled ? 'text-gray-100' : error ? 'text-red' : 'text-gray-100'
            )}
        >
            {children}
        </span>
    )
}
