import type { ReactNode } from 'react'
import type { IconType } from 'react-icons'
import classNames from 'classnames'
import {
    RiCheckboxCircleLine as SuccessIcon,
    RiCloseFill as CloseIcon,
    RiErrorWarningLine as ErrorIcon,
    RiInformationLine as InfoIcon,
} from 'react-icons/ri'

export type AlertVariant = 'info' | 'error' | 'success'

const backgroundVariants: { [key in AlertVariant]: string } = Object.freeze({
    info: 'bg-gray-400 text-white',
    error: 'bg-red text-red bg-opacity-10',
    success: 'bg-teal text-teal bg-opacity-10',
})

const iconVariants: { [key in AlertVariant]: IconType } = Object.freeze({
    info: InfoIcon,
    error: ErrorIcon,
    success: SuccessIcon,
})

export interface AlertProps {
    // Indicates if Alert is visible or not.
    isVisible: boolean
    // Renders a close button a callback is passed.
    onClose?: () => void
    // Text/Content displayed in the Alert.
    children: ReactNode
    // Alert variants.
    variant?: AlertVariant
    // Custom icon
    icon?: IconType
    className?: string
}

function Alert({
    isVisible,
    onClose,
    children,
    className,
    icon,
    variant = 'info',
}: AlertProps): JSX.Element | null {
    // For now we can close it abruptly to avoid spending time on any overoptimization, but this can
    // be later be improved to use a transition instead.
    if (!isVisible) {
        return null
    }

    const Icon = icon || iconVariants[variant]

    return (
        <div className={classNames(className, 'rounded flex ' + backgroundVariants[variant])}>
            <div className="py-2 flex">
                <div className="shrink-0 ml-4">{<Icon fontSize={20} />}</div>

                <span className="text-base ml-2 mr-1">{children}</span>
            </div>

            {onClose && (
                <div className="ml-auto items-start mt-1.5 mr-4">
                    <button onClick={onClose} title="Close">
                        <CloseIcon fontSize={24} />
                    </button>
                </div>
            )}
        </div>
    )
}

export default Alert
