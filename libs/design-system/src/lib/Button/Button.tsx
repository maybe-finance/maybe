import type { PropsWithChildren, ReactNode } from 'react'
import React from 'react'
import classNames from 'classnames'

const ButtonVariants = Object.freeze({
    primary:
        'px-4 py-2 rounded text-base bg-cyan text-gray-700 shadow hover:bg-cyan-400 focus:bg-cyan-400 focus:ring-cyan',
    secondary:
        'px-4 py-2 rounded text-base bg-gray-500 text-gray-25 shadow hover:bg-gray-400 focus:bg-gray-400 focus:ring-gray-400',
    input: 'px-4 py-2 rounded text-base bg-transparent text-gray-25 border border-gray-200 shadow focus:bg-gray-500 focus:ring-gray-400',
    link: 'px-4 py-2 rounded text-base text-cyan hover:text-cyan-400 focus:text-cyan-300 focus:ring-cyan',
    icon: 'p-0 w-8 h-8 rounded text-2xl text-gray-25 hover:bg-gray-300 focus:bg-gray-200 focus:ring-gray-400',
    danger: 'px-4 py-2 rounded text-base bg-red text-gray-700 shadow hover:bg-red-400 focus:bg-red-400 focus:ring-red',
    warn: 'px-4 py-2 rounded text-base bg-gray-500 text-red-500 shadow hover:bg-gray-400 focus:bg-gray-400 focus:ring-red',
})

export type ButtonVariant = keyof typeof ButtonVariants

export type ButtonProps = Omit<React.ButtonHTMLAttributes<HTMLButtonElement>, 'as'> &
    PropsWithChildren<{
        variant?: ButtonVariant

        onClick?: () => void

        disabled?: boolean

        /** Display as a full-width block */
        fullWidth?: boolean

        /** Will use an 'a' tag if specified */
        href?: string

        /** 'a' download attribute */
        download?: string

        /** 'a' target attribute */
        target?: string

        /** Element to use (default is <button> or <a> depending on props) */
        as?: React.ElementType

        className?: string

        leftIcon?: ReactNode
    }>

function Button(
    {
        variant = 'primary',
        fullWidth = false,
        href,
        as,
        children,
        className,
        leftIcon,
        ...rest
    }: ButtonProps,
    ref: React.Ref<HTMLElement>
): JSX.Element {
    const combinedClassName = classNames(
        className,
        ButtonVariants[variant],
        fullWidth && 'w-full',
        'inline-flex items-center justify-center text-center',
        'font-medium leading-6 whitespace-nowrap select-none cursor-pointer',
        'focus:outline-none focus:ring focus:ring-opacity-60',
        'disabled:opacity-50 disabled:pointer-events-none',
        'transition-colors duration-200'
    )

    const Tag = as || (href ? 'a' : 'button')

    return (
        <Tag
            ref={ref}
            className={combinedClassName}
            role="button"
            {...(Tag === 'button' && { type: 'button' })}
            {...(href && { href })} // Adds href only if exists.
            {...rest}
        >
            {leftIcon && <span className="mr-1.5">{leftIcon}</span>}
            {children}
        </Tag>
    )
}

export default React.forwardRef(Button)
