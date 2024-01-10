import classNames from 'classnames'
import { Switch } from '@headlessui/react'

const ToggleSizes = Object.freeze({
    small: {
        outer: 'h-6 w-11',
        inner: 'h-4 w-4',
        innerChecked: 'translate-x-5',
    },
    medium: {
        outer: 'h-8 w-14',
        inner: 'h-6 w-6',
        innerChecked: 'translate-x-6',
    },
})

export type ToggleSize = keyof typeof ToggleSizes

export interface ToggleProps {
    onChange(checked: boolean): void
    checked?: boolean
    size?: ToggleSize
    screenReaderLabel?: string
    className?: string
    disabled?: boolean
}

export default function Toggle({
    checked = false,
    disabled = false,
    size = 'medium',
    className,
    screenReaderLabel,
    ...rest
}: ToggleProps) {
    return (
        <Switch
            checked={checked}
            disabled={disabled}
            className={classNames(
                className,
                checked ? 'bg-cyan focus:ring-cyan' : 'bg-gray-600 focus:ring-gray',
                disabled && 'bg-gray-500 cursor-not-allowed',
                'relative inline-flex shrink-0 border-2 border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200 focus:ring-2 focus:outline-none focus:ring-opacity-60 p-0.5',
                ToggleSizes[size].outer
            )}
            {...rest}
        >
            {screenReaderLabel && <span className="sr-only">{screenReaderLabel}</span>}
            <span
                className={classNames(
                    checked
                        ? [ToggleSizes[size].innerChecked, 'bg-white']
                        : 'translate-x-0 bg-gray-200',
                    disabled && 'bg-gray-300',
                    'pointer-events-none inline-block rounded-full shadow transform ring-0 transition ease-in-out duration-200',
                    ToggleSizes[size].inner
                )}
            />
        </Switch>
    )
}
