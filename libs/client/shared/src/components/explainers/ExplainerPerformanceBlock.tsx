import classNames from 'classnames'
import type { ReactNode } from 'react'

const variants = {
    teal: {
        color: 'text-teal',
        className: 'from-teal/[0.15]',
    },
    red: {
        color: 'text-red',
        className: 'from-red/[0.1]',
    },
    yellow: {
        color: 'text-yellow',
        className: 'from-yellow/[0.1]',
    },
}

export type ExplainerPerformanceBlockProps = {
    variant: keyof typeof variants
    children: ReactNode | ((color: string) => ReactNode)
}

export function ExplainerPerformanceBlock({
    variant,
    children,
}: ExplainerPerformanceBlockProps): JSX.Element {
    return (
        <div
            className={classNames(
                'mt-3 mb-5 p-3 rounded-lg text-white bg-gradient-to-b',
                variants[variant].className
            )}
        >
            {typeof children === 'function' ? children(variants[variant].color) : children}
        </div>
    )
}
