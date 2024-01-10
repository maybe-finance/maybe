import { useScreenSize, SCREEN, Toaster } from '@maybe-finance/client/shared'
import { useEffect, useState } from 'react'
import { Breadcrumb, Button } from '@maybe-finance/design-system'
import { RiCloseLine } from 'react-icons/ri'
import Link from 'next/link'

type Path = {
    title: string
    href?: string
}

export interface WithOnboardingLayoutProps {
    paths: Path[]
    children: React.ReactNode
}

export function WithOnboardingLayout({ paths, children }: WithOnboardingLayoutProps) {
    const screen = useScreenSize()

    const [isMounted, setIsMounted] = useState(false)
    useEffect(() => {
        setIsMounted(true)
    }, [])

    if (!isMounted) return null

    return (
        <div className="p-4 sm:p-12 h-screen custom-gray-scroll flex justify-center">
            <div className="h-full w-full max-w-screen-xl flex flex-col items-center">
                <Toaster
                    mobile={screen === SCREEN.MOBILE}
                    sidebarOffset={screen === SCREEN.DESKTOP ? 'ml-96' : undefined}
                />

                {/* Mobile only - shows breadcrumbs and close icon at top of content */}
                <div className="lg:hidden w-full flex items-center justify-around gap-4 mb-8 pt-4">
                    <Breadcrumb.Group>
                        {paths.map((path) => (
                            <Breadcrumb key={path.title} href={path.href}>
                                {path.title}
                            </Breadcrumb>
                        ))}
                    </Breadcrumb.Group>
                    <Link href={paths[0]?.href ?? '/'} passHref legacyBehavior>
                        <Button variant="icon">
                            <RiCloseLine className="w-6 h-6" />
                        </Button>
                    </Link>
                </div>

                <div className="flex justify-between h-full lg:w-full">
                    <Breadcrumb.Group className="self-start hidden lg:inline-flex">
                        {paths.map((path) => (
                            <Breadcrumb key={path.title} href={path.href}>
                                {path.title}
                            </Breadcrumb>
                        ))}
                    </Breadcrumb.Group>
                    <div className="max-w-lg flex justify-center h-full">{children}</div>
                    <div className="lg:w-[200px] hidden lg:flex lg:justify-end">
                        <Link href={paths[0]?.href ?? '/'} passHref legacyBehavior>
                            <Button variant="icon">
                                <RiCloseLine className="w-6 h-6" />
                            </Button>
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    )
}

export default WithOnboardingLayout
