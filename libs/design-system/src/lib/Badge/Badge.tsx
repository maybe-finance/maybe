import type { ReactNode, HTMLAttributes } from 'react'
import classNames from 'classnames'

const BadgeVariants = Object.freeze({
    teal: {
        normal: 'text-teal bg-teal bg-opacity-10',
        highlighted: 'text-gray-800 bg-teal',
    },
    red: {
        normal: 'text-red bg-red bg-opacity-10',
        highlighted: 'text-gray-800 bg-red',
    },
    gray: {
        normal: 'text-white bg-gray-700',
        highlighted: 'text-gray-800 bg-gray-100',
    },
    cyan: {
        normal: 'text-cyan bg-cyan bg-opacity-10',
        highlighted: 'text-gray-800 bg-cyan',
    },
    plain: {
        normal: '',
        highlighted: '',
    },
    warn: {
        normal: 'text-yellow bg-yellow bg-opacity-10',
        highlighted: 'text-gray-800 bg-yellow',
    },
})

export type BadgeVariant = keyof typeof BadgeVariants

const SizeVariant = Object.freeze({
    sm: 'px-1.5 py-1 text-sm',
    md: 'px-2 py-1 text-base',
})

export interface BadgeProps extends HTMLAttributes<HTMLElement> {
    variant?: BadgeVariant

    size?: 'sm' | 'md'

    /** Whether the badge is in a brighter highlighted state */
    highlighted?: boolean

    /** Whether the badge will be used to display numerical data */
    numeric?: boolean

    /** Element to use (defaults to <div>) */
    as?: React.ElementType

    className?: string

    children: ReactNode
}

function Badge({
    variant = 'teal',
    size = 'md',
    highlighted = false,
    numeric = true,
    as = 'div',
    className,
    children,
    ...rest
}: BadgeProps): JSX.Element {
    const classes = classNames(
        className,
        BadgeVariants[variant][highlighted ? 'highlighted' : 'normal'],
        SizeVariant[size],
        numeric && 'tabular-nums',
        'inline-block font-medium rounded'
    )

    const Tag = as

    return (
        <Tag className={classes} {...rest}>
            {children}
        </Tag>
    )
}

export default Badge
