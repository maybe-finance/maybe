import { SCREEN, useScreenSize, Toaster } from '@maybe-finance/client/shared'
import { type PropsWithChildren, useEffect, useState } from 'react'

export function FullPageLayout({ children }: PropsWithChildren) {
    const screen = useScreenSize()

    const [isMounted, setIsMounted] = useState(false)
    useEffect(() => {
        setIsMounted(true)
    }, [])

    if (!isMounted) return null

    return (
        <>
            <Toaster mobile={screen === SCREEN.MOBILE} />
            <div className="fixed h-full w-full custom-gray-scroll flex flex-col">{children}</div>
        </>
    )
}

export default FullPageLayout
