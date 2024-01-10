import type { PropsWithChildren } from 'react'
import { Button } from '@maybe-finance/design-system'
import { Overlay } from './Overlay'

export type MainContentOverlayProps = PropsWithChildren<{
    title: string
    actionText: string
    onAction: () => void
}>

export function MainContentOverlay({
    children,
    title,
    actionText,
    onAction,
}: MainContentOverlayProps) {
    return (
        <Overlay>
            <div className="absolute inset-0 flex flex-col items-center justify-center h-full">
                <h4 className="mb-2">{title}</h4>
                <div className="text-base text-gray-100 max-w-sm text-center mb-4">{children}</div>
                <Button onClick={onAction}>{actionText}</Button>
            </div>
        </Overlay>
    )
}
