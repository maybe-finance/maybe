import type { ReactNode } from 'react'

export interface SwatchGroupProps {
    heading: string
    description?: string
    children: ReactNode
}

function SwatchGroup({ heading, description, children }: SwatchGroupProps): JSX.Element {
    return (
        <div className="flex my-12">
            <div className="w-96 shrink-0 mr-8">
                <h2 className="font-display font-bold text-xl text-white uppercase">{heading}</h2>
                {description && <p className="text-base text-gray-200">{description}</p>}
            </div>
            <div className="grow">{children}</div>
        </div>
    )
}

export default SwatchGroup
