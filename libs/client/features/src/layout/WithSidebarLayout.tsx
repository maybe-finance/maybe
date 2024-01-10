import { useScreenSize, SCREEN, Toaster, PopoutProvider } from '@maybe-finance/client/shared'
import MobileLayout from './MobileLayout'
import DesktopLayout from './DesktopLayout'
import { useEffect, useState } from 'react'

export interface WithSidebarLayoutProps {
    sidebar: React.ReactNode
    children: React.ReactNode
}

export function WithSidebarLayout({ sidebar, children }: WithSidebarLayoutProps) {
    const screen = useScreenSize()

    // Due to SSR and the conditional components we are loading based on screen size,
    // ensure that app is mounted to prevent rehydration issues
    const [isMounted, setIsMounted] = useState(false)
    useEffect(() => {
        setIsMounted(true)
    }, [])

    if (!isMounted) return null

    return (
        <PopoutProvider>
            <Toaster
                mobile={screen === SCREEN.MOBILE}
                sidebarOffset={screen === SCREEN.DESKTOP ? 'ml-96' : undefined}
            />

            {screen === SCREEN.MOBILE ? (
                <MobileLayout sidebar={sidebar}>{children}</MobileLayout>
            ) : (
                <DesktopLayout sidebar={sidebar}>{children}</DesktopLayout>
            )}
        </PopoutProvider>
    )
}

export default WithSidebarLayout
