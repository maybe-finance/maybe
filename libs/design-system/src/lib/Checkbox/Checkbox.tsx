import { Switch } from '@headlessui/react'
import classNames from 'classnames'
import type { ReactNode } from 'react'

export interface CheckboxProps {
    label?: ReactNode
    checked?: boolean
    onChange?: (checked: boolean) => void
    className?: string
    wrapperClassName?: string
    disabled?: boolean
    dark?: boolean
}

export default function Checkbox({
    label,
    checked = false,
    className,
    wrapperClassName,
    disabled = false,
    onChange,
    dark = false,
    ...rest
}: CheckboxProps): JSX.Element {
    return (
        <Switch.Group>
            <div
                className={classNames(
                    wrapperClassName,
                    'flex items-center space-x-3 text-white text-base'
                )}
            >
                <Switch
                    checked={checked}
                    disabled={disabled}
                    className={classNames(
                        className,
                        !checked && dark && 'bg-black',
                        checked ? 'bg-cyan border-cyan focus:ring-cyan' : 'focus:ring-gray',
                        disabled && 'bg-gray-700 cursor-not-allowed',
                        'shrink-0 flex items-center justify-center w-4 h-4 border border-gray-200 rounded cursor-pointer',
                        'focus:ring-2 focus:outline-none focus:ring-opacity-60',
                        'transition-colors ease-in-out duration-200'
                    )}
                    onChange={(checked: boolean) => onChange && onChange(checked)}
                    {...rest}
                >
                    {checked && (
                        <svg
                            viewBox="0 0 9 8"
                            className="text-black h-2 ml-px"
                            fill="currentColor"
                            xmlns="http://www.w3.org/2000/svg"
                        >
                            <path d="M2.5279 7.00293C2.61863 7.09961 2.74531 7.15445 2.8779 7.15445C3.01049 7.15445 3.13717 7.09961 3.2279 7.00293L8.8479 1.38293C8.94256 1.28905 8.9958 1.16125 8.9958 1.02793C8.9958 0.89461 8.94256 0.766812 8.8479 0.672929L8.3179 0.142929C8.12348 -0.0476429 7.81232 -0.0476429 7.6179 0.142929L2.8779 4.88293L1.3779 3.39293C1.28717 3.29625 1.16049 3.24141 1.0279 3.24141C0.895313 3.24141 0.768633 3.29625 0.677899 3.39293L0.147899 3.92293C0.0532428 4.01681 0 4.14461 0 4.27793C0 4.41125 0.0532428 4.53904 0.147899 4.63293L2.5279 7.00293Z" />
                        </svg>
                    )}
                </Switch>
                {label && <Switch.Label>{label}</Switch.Label>}
            </div>
        </Switch.Group>
    )
}
