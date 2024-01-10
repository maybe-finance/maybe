import type { ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { useLayoutContext } from '../../providers'

export function Overlay({ children }: { children: ReactNode }) {
    const { overlayContainer } = useLayoutContext()

    return overlayContainer?.current ? (
        createPortal(children, overlayContainer.current)
    ) : (
        // eslint-disable-next-line react/jsx-no-useless-fragment
        <>{children}</>
    )
}
