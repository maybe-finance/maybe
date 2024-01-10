import type { IconType } from 'react-icons'

import classNames from 'classnames'

const Size = {
    sm: 'w-6 h-6 rounded-sm',
    md: 'w-[36px] h-[36px] rounded-lg',
    lg: 'w-12 h-12 rounded-xl',
}

const Variant = {
    cyan: 'bg-cyan text-cyan',
    orange: 'bg-orange text-orange',
    teal: 'bg-teal text-teal',
    grape: 'bg-grape text-grape',
    pink: 'bg-pink text-pink',
    yellow: 'bg-yellow text-yellow',
    blue: 'bg-blue text-blue',
    red: 'bg-red text-red',
    indigo: 'bg-indigo text-indigo',
}

export type BoxIconVariant = keyof typeof Variant
export type BoxIconSize = keyof typeof Size

export type BoxIconProps = {
    icon: IconType
    variant?: BoxIconVariant
    size?: BoxIconSize
}

export function BoxIcon({ icon: Icon, size = 'lg', variant = 'cyan' }: BoxIconProps) {
    return (
        <div
            className={classNames(
                'flex items-center justify-center bg-opacity-10 shrink-0',
                Variant[variant],
                Size[size]
            )}
        >
            <Icon className={size === 'lg' ? 'w-6 h-6' : 'w-4 h-4'} />
        </div>
    )
}
