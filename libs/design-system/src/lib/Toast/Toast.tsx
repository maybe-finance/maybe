import type { ReactNode, HTMLAttributes } from 'react'
import classNames from 'classnames'
import {
    RiInformationLine as IconInfo,
    RiCheckboxCircleLine as IconSuccess,
    RiErrorWarningLine as IconError,
} from 'react-icons/ri'

const ToastVariants = Object.freeze({
    info: {
        className: 'text-white bg-gray-500',
        icon: IconInfo,
        role: 'status',
    },
    success: {
        className: 'text-black bg-teal',
        icon: IconSuccess,
        role: 'status',
    },
    error: {
        className: 'text-black bg-red',
        icon: IconError,
        role: 'alert',
    },
})

export type ToastVariant = keyof typeof ToastVariants

export interface ToastProps extends HTMLAttributes<HTMLDivElement> {
    variant?: ToastVariant

    onClick?: () => void

    className?: string

    children?: ReactNode
}

function Toast({ variant = 'info', children, className, ...rest }: ToastProps): JSX.Element {
    const combinedClassName = classNames(
        className,
        ToastVariants[variant].className,
        'flex items-center py-2 px-4 rounded shadow-md'
    )

    const Icon = ToastVariants[variant].icon

    return (
        <div className={combinedClassName} {...rest}>
            <Icon className="shrink-0 mr-2 text-xl" />
            <output className="text-base" role={ToastVariants[variant].role}>
                {children}
            </output>
        </div>
    )
}

export default Toast
