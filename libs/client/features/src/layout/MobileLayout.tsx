import React, { useEffect, useMemo, useRef, useState } from 'react'
import { motion } from 'framer-motion'
import {
    RiChatPollLine,
    RiCloseLine,
    RiFlagLine,
    RiFolderOpenLine,
    RiMenuLine,
    RiMore2Fill,
    RiPieChart2Line,
} from 'react-icons/ri'
import { Button } from '@maybe-finance/design-system'
import { MenuPopover } from './MenuPopover'
import Link from 'next/link'
import { useRouter } from 'next/router'
import { ProfileCircle } from '@maybe-finance/client/shared'
import { usePopoutContext, LayoutContextProvider } from '@maybe-finance/client/shared'
import { UpgradePrompt } from '../user-billing'
import classNames from 'classnames'
import type { IconType } from 'react-icons'

export interface MobileLayoutProps {
    sidebar: React.ReactNode
    children: React.ReactNode
}

const AsideVariants = {
    expanded: {
        transform: 'translateX(0%)',
    },
    collapsed: {
        transform: 'translateX(-100%)',
    },
    popout: {
        transform: 'translateX(-100%)',
    },
}

const MainVariants = {
    expanded: {
        transform: 'translateX(100%)',
    },
    collapsed: {
        transform: 'translateX(0%)',
    },
    popout: {
        transform: 'translateX(-100%)',
    },
}

const PopoutVariants = {
    expanded: {
        transform: 'translateX(100%)',
    },
    collapsed: {
        transform: 'translateX(100%)',
    },
    popout: {
        transform: 'translateX(0)',
    },
}

function NavItem({
    href,
    icon: Icon,
    label,
    active,
}: {
    href: string
    icon: IconType
    label: string
    active?: (pathname: string) => boolean
}) {
    const { pathname } = useRouter()

    const isActive = active ? active(pathname) : pathname === href

    return (
        <li>
            <div>
                <Link
                    href={href}
                    passHref
                    className={classNames(
                        'relative flex flex-col items-center w-[82px] py-3 rounded-lg cursor-pointer text-gray-100 hover:text-gray-50 transition-colors',
                        isActive && 'text-gray-25'
                    )}
                >
                    {isActive && (
                        <motion.div
                            layoutId="nav-selection"
                            className="absolute inset-0"
                            transition={{ duration: 0.3 }}
                        >
                            <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-5 h-1 bg-white rounded-t-lg"></div>
                        </motion.div>
                    )}
                    <Icon className="shrink-0 w-6 h-6" />
                    <span className="shrink-0 mt-1.5 text-sm font-medium text-center">{label}</span>
                </Link>
            </div>
        </li>
    )
}

export function MobileLayout({ children, sidebar }: MobileLayoutProps) {
    const overlayContainer = useRef<HTMLDivElement>(null)

    const { popoutContents, close: closePopout } = usePopoutContext()

    const [collapsed, setCollapsed] = useState(true)
    const layout = useMemo(() => {
        if (popoutContents) return 'popout'

        return collapsed ? 'collapsed' : 'expanded'
    }, [collapsed, popoutContents])

    const router = useRouter()

    useEffect(() => {
        router.events.on('routeChangeComplete', () => {
            setCollapsed(true)
            closePopout()
        })

        return () => {
            router.events.off('routeChangeComplete', () => undefined)
        }
    }, [router, closePopout])

    return (
        <div>
            <motion.aside
                layout
                initial={false}
                animate={layout}
                variants={AsideVariants}
                transition={{ duration: 0.4 }}
                className="fixed w-full h-screen"
            >
                <div>
                    <nav>
                        <div className="flex items-center justify-between px-4 h-20">
                            <div className="w-10">
                                <Button variant="icon" onClick={() => setCollapsed(true)}>
                                    <RiCloseLine className="w-6 h-6" />
                                </Button>
                            </div>
                            <Link href="/" className="flex items-center cursor-pointer">
                                <img
                                    src="/assets/maybe.svg"
                                    alt="Maybe Finance Logo"
                                    height={36}
                                    width={36}
                                />
                            </Link>
                            <Link href="/settings">
                                <ProfileCircle className="!w-10 !h-10" />
                            </Link>
                        </div>
                        <ul className="flex items-end justify-center xs:gap-2 border-b border-gray-700">
                            <NavItem label="Net worth" href="/" icon={RiPieChart2Line} />
                            <NavItem label="Accounts" href="/accounts" icon={RiFolderOpenLine} />
                            <NavItem
                                label="Planning"
                                href="/plans"
                                icon={RiFlagLine}
                                active={(path) => path.startsWith('/plans')}
                            />
                        </ul>
                    </nav>
                    <div className="flex flex-col h-[calc(100vh-80px)] px-4 pt-6 pb-24">
                        <section className="grow h-[calc(100vh-80px)] custom-gray-scroll">
                            {sidebar}
                        </section>

                        <div className="shrink-0 pt-6"></div>
                    </div>
                </div>
            </motion.aside>

            <motion.div
                layout
                initial={false}
                animate={layout}
                variants={MainVariants}
                transition={{ duration: 0.4 }}
                className="fixed w-full"
            >
                <header className="flex items-center justify-between h-20 px-4">
                    <Button variant="icon" onClick={() => setCollapsed(false)}>
                        <RiMenuLine className="w-6 h-6" />
                    </Button>
                    <Link href="/" className="flex items-center cursor-pointer">
                        <img
                            src="/assets/maybe.svg"
                            alt="Maybe Finance Logo"
                            height={36}
                            width={36}
                        />
                    </Link>
                    <MenuPopover isHeader={false} icon={<RiMore2Fill />} placement="bottom-end" />
                </header>

                <main
                    id="mainScrollArea"
                    className="relative px-4 pt-6 h-[calc(100vh-80px)] custom-gray-scroll"
                >
                    <LayoutContextProvider overlayContainer={overlayContainer}>
                        <div className="relative min-h-full pb-24">
                            {children}
                            <div ref={overlayContainer}></div>
                        </div>
                    </LayoutContextProvider>
                </main>
            </motion.div>
            <motion.aside
                variants={PopoutVariants}
                initial={false}
                animate={layout}
                transition={{ duration: 0.4 }}
                className="fixed w-full h-screen bg-gray-800 custom-gray-scroll"
            >
                {layout === 'popout' && popoutContents}
            </motion.aside>
        </div>
    )
}

export default MobileLayout
