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
    profileIcon: 'p-0 w-12 h-12 rounded text-2xl text-gray-25',
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

        /** Display spinner based on the value passed */
        isLoading?: boolean
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
        isLoading = false,
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
            {isLoading && Tag === 'button' && (
                <span className="ml-1.5">
                    <Spinner fill={variant === 'primary' ? '#16161A' : '#FFFFFF'} />
                </span>
            )}
        </Tag>
    )
}

// Add a spinner to Button component and toggle it via flag

interface SpinnerProps {
    fill: string
}

function Spinner({ fill }: SpinnerProps): JSX.Element {
    return (
        <svg width="20" height="20" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path
                d="M12,1A11,11,0,1,0,23,12,11,11,0,0,0,12,1Zm0,19a8,8,0,1,1,8-8A8,8,0,0,1,12,20Z"
                opacity=".25"
                fill={fill}
            />
            <path
                d="M10.72,19.9a8,8,0,0,1-6.5-9.79A7.77,7.77,0,0,1,10.4,4.16a8,8,0,0,1,9.49,6.52A1.54,1.54,0,0,0,21.38,12h.13a1.37,1.37,0,0,0,1.38-1.54,11,11,0,1,0-12.7,12.39A1.54,1.54,0,0,0,12,21.34h0A1.47,1.47,0,0,0,10.72,19.9Z"
                fill={fill}
            >
                <animateTransform
                    attributeName="transform"
                    type="rotate"
                    dur="0.75s"
                    values="0 12 12;360 12 12"
                    repeatCount="indefinite"
                />
            </path>
        </svg>
    )
}

export default React.forwardRef(Button)
