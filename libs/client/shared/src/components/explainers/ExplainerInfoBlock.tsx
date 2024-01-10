import type { ReactNode } from 'react'

export type ExplainerInfoBlockProps = {
    title: string | ReactNode
    children: ReactNode
}

export function ExplainerInfoBlock({ title, children }: ExplainerInfoBlockProps): JSX.Element {
    return (
        <div className="my-3 py-2 px-3 rounded-lg bg-gray-600">
            <span className="font-medium text-sm text-gray-100 uppercase">{title}</span>
            <div className="mt-1 text-base text-gray-25">{children}</div>
        </div>
    )
}
