import { Button } from '@maybe-finance/design-system'
import type { ReactNode } from 'react'
import { RiCloseFill } from 'react-icons/ri'
import { usePopoutContext } from '../../providers'

export type InsightPopoutProps = {
    children: ReactNode
}

export function InsightPopout({ children }: InsightPopoutProps) {
    const { close } = usePopoutContext()

    return (
        <div className="flex flex-col h-full overflow-hidden w-full lg:w-96">
            <div className="p-4">
                <Button variant="icon" title="Close" onClick={close}>
                    <RiCloseFill className="w-6 h-6" />
                </Button>
            </div>
            <div className="grow">{children}</div>
        </div>
    )
}
