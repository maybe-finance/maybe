import type { PropsWithChildren } from 'react'
import { Button } from '@maybe-finance/design-system'
import { usePopoutContext } from '@maybe-finance/client/shared'
import { RiCloseFill } from 'react-icons/ri'

type PlanEventListProps = PropsWithChildren<{}>

export function PlanEventPopout({ children }: PlanEventListProps) {
    const { close } = usePopoutContext()

    return (
        <div className="flex flex-col h-full w-full lg:w-[384px] p-6">
            <Button variant="icon" title="Close" onClick={close}>
                <RiCloseFill className="w-6 h-6" />
            </Button>
            <div className="flex flex-col grow mt-6">{children}</div>
        </div>
    )
}
