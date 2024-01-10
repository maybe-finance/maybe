import Link from 'next/link'
import type { ReactNode } from 'react'
import type { IconType } from 'react-icons'

export type ExplainerExternalLinkProps = {
    icon: IconType
    href: string
    children: ReactNode
}

export function ExplainerExternalLink({
    icon: Icon,
    href,
    children,
}: ExplainerExternalLinkProps): JSX.Element {
    return (
        <Link
            href={href}
            rel="noreferrer"
            target="_blank"
            className="flex gap-2 my-2 p-2 rounded-lg bg-gray-600 text-base hover:bg-gray-500 transition-color"
        >
            <Icon className="shrink-0 w-6 h-6 text-gray-100" />
            <span className="text-gray-25">{children}</span>
        </Link>
    )
}
