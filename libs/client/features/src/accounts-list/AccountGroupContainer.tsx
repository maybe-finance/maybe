import type { PropsWithChildren } from 'react'

export type AccountGroupContainerProps = PropsWithChildren<{
    title: string
    subtitle?: string
}>

export function AccountGroupContainer({
    title,
    subtitle = '',
    children,
}: AccountGroupContainerProps) {
    return (
        <section>
            <header>
                <h5>{title}</h5>
                <p className="text-gray-100 text-base">{subtitle}</p>
            </header>
            <ul className="mt-4 space-y-2">{children}</ul>
        </section>
    )
}
