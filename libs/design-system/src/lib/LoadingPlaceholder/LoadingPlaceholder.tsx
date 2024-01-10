import type { ReactNode } from 'react'
import classNames from 'classnames'

export default function LoadingPlaceholder({
    isLoading = true,
    children,
    className,
    overlayClassName,
    maxContent = false,
    placeholderContent,
}: {
    isLoading?: boolean
    children?: ReactNode
    className?: string
    overlayClassName?: string
    maxContent?: boolean
    placeholderContent?: ReactNode
}): JSX.Element {
    return (
        <div
            className={classNames(
                'relative overflow-hidden rounded',
                maxContent && 'max-w-max',
                className
            )}
        >
            {isLoading && placeholderContent ? placeholderContent : children}
            {isLoading && (
                <>
                    <div className={classNames('absolute inset-0 bg-gray-700', overlayClassName)} />
                    <div className="absolute inset-0 bg-shine animate-shine"></div>
                </>
            )}
        </div>
    )
}
