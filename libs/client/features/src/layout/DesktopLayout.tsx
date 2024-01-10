import classNames from 'classnames'
import {
    ProfileCircle,
    useAccountContext,
    usePopoutContext,
    LayoutContextProvider,
    useUserApi,
} from '@maybe-finance/client/shared'
import { useMemo, useState, useEffect, useRef, type PropsWithChildren, type ReactNode } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import Link from 'next/link'
import { useRouter } from 'next/router'
import type { IconType } from 'react-icons'
import {
    RiAddFill,
    RiFolderOpenLine,
    RiMenuFoldLine,
    RiMenuUnfoldLine,
    RiMore2Fill,
    RiPieChart2Line,
    RiFlagLine,
    RiChatPollLine,
    RiArrowRightSLine,
} from 'react-icons/ri'
import { Button, Tooltip } from '@maybe-finance/design-system'
import { useAuth0 } from '@auth0/auth0-react'
import { MenuPopover } from './MenuPopover'
import { UpgradePrompt } from '../user-billing'
import { SidebarOnboarding } from '../onboarding'

export interface DesktopLayoutProps {
    sidebar: React.ReactNode
    children: React.ReactNode
}

const LayoutVariants = {
    collapsed: {
        gridTemplateColumns: '88px 0px 1fr 0px',
    },
    expanded: {
        gridTemplateColumns: '88px 330px 1fr 0px',
    },
    popout: {
        gridTemplateColumns: '88px 0px 1fr 384px',
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
                        'relative flex flex-col items-center w-[88px] rounded-lg cursor-pointer text-gray-100 hover:text-gray-50 transition-colors',
                        isActive && 'text-gray-25'
                    )}
                >
                    {isActive && (
                        <motion.div
                            layoutId="nav-selection"
                            className="absolute inset-0"
                            transition={{ duration: 0.3 }}
                        >
                            <div className="absolute left-0 w-1 h-5 -translate-y-1/2 bg-white rounded-r-lg top-1/2"></div>
                        </motion.div>
                    )}
                    <Icon className="w-6 h-6 shrink-0" />
                    <span className="shrink-0 mt-1.5 text-sm font-medium text-center">{label}</span>
                </Link>
            </div>
        </li>
    )
}

export function DesktopLayout({ children, sidebar }: DesktopLayoutProps) {
    const overlayContainer = useRef<HTMLDivElement>(null)
    const router = useRouter()

    const [onboardingExpanded, setOnboardingExpanded] = useState(false)

    const { popoutContents, close: closePopout } = usePopoutContext()
    const { user } = useAuth0()
    const { useOnboarding, useUpdateOnboarding } = useUserApi()
    const onboarding = useOnboarding('sidebar')
    const updateOnboarding = useUpdateOnboarding()

    const [collapsed, setCollapsed] = useState(false)
    const layout = useMemo(() => {
        if (popoutContents) return 'popout'

        return collapsed ? 'collapsed' : 'expanded'
    }, [collapsed, popoutContents])

    useEffect(() => {
        router.events.on('routeChangeComplete', () => closePopout())

        return () => {
            router.events.off('routeChangeComplete', () => undefined)
        }
    }, [router, closePopout])

    const showOnboardingOverride = router.query.show_sidebar_onboarding === 'true'

    const hideOnboardingWidgetForever = () => {
        // User does not want to see onboarding widget anymore, so mark flow complete
        updateOnboarding.mutate({
            flow: 'sidebar',
            updates: [],
            markedComplete: true,
        })
    }

    // This flow requires the user to "mark flow complete" to remove the widget
    const showWidget =
        showOnboardingOverride || (onboarding.data && !onboarding.data.isMarkedComplete)

    return (
        <motion.div
            className="min-h-screen grid grid-rows-[100vh] bg-gray-800"
            layout
            variants={LayoutVariants}
            animate={layout}
            initial={false}
            transition={{ duration: 0.4 }}
        >
            <nav className="flex flex-col items-center justify-between pt-8 pb-6 border-r border-gray-700">
                <div className="flex flex-col items-center">
                    <Link href="/">
                        <img
                            src="/assets/maybe.svg"
                            alt="Maybe Finance Logo"
                            className="mb-6"
                            height={36}
                            width={36}
                        />
                    </Link>

                    <motion.ul
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        className="flex flex-col items-center gap-5 mt-4"
                    >
                        <NavItem label="Net worth" href="/" icon={RiPieChart2Line} />
                        <NavItem label="Accounts" href="/accounts" icon={RiFolderOpenLine} />
                        <NavItem
                            label="Planning"
                            href="/plans"
                            icon={RiFlagLine}
                            active={(path) => path.startsWith('/plans')}
                        />
                        <NavItem
                            label="Advisor"
                            href="/ask-the-advisor"
                            icon={RiChatPollLine}
                            active={(path) => path.startsWith('/ask-the-advisor')}
                        />
                    </motion.ul>
                </div>

                <div className="flex flex-col items-center gap-3">
                    <Tooltip
                        content={layout === 'expanded' ? 'Minimize' : 'Maximize'}
                        placement="right"
                    >
                        <div
                            className="flex items-center justify-center w-12 h-12 p-2 rounded-lg cursor-pointer hover:bg-gray-500"
                            onClick={() => {
                                if (layout === 'expanded') {
                                    setCollapsed(true)
                                } else {
                                    setCollapsed(false)
                                    closePopout()
                                }
                            }}
                        >
                            {layout === 'expanded' ? (
                                <RiMenuFoldLine className="w-6 h-6" />
                            ) : (
                                <RiMenuUnfoldLine className="w-6 h-6" />
                            )}
                        </div>
                    </Tooltip>

                    <Link href="/settings">
                        <ProfileCircle />
                    </Link>
                </div>
            </nav>

            <motion.aside
                variants={{
                    expanded: { opacity: [0, 1] },
                    collapsed: { opacity: 0 },
                    popout: { opacity: 0 },
                }}
                layout="position"
                animate={layout}
                className="flex flex-col gap-4 px-4 pt-8 pb-6 bg-gray-800"
            >
                {layout === 'expanded' &&
                    (onboardingExpanded && showWidget ? (
                        <SidebarOnboarding
                            onClose={() => setOnboardingExpanded(false)}
                            onHide={() => {
                                setOnboardingExpanded(false)
                                hideOnboardingWidgetForever()
                            }}
                        />
                    ) : (
                        <DefaultContent
                            onboarding={
                                <AnimatePresence>
                                    {onboarding.data && showWidget && (
                                        <motion.div
                                            initial={{ opacity: 0 }}
                                            animate={{ opacity: 1 }}
                                            exit={{ opacity: 0 }}
                                            className="p-3 text-base bg-gray-700 rounded-lg cursor-pointer hover:bg-gray-600"
                                            onClick={() => setOnboardingExpanded(true)}
                                        >
                                            <div className="flex items-center justify-between text-sm mb-1">
                                                <p className="text-gray-50">Getting started</p>
                                                {onboarding.data.isComplete && (
                                                    <button
                                                        onClick={(e) => {
                                                            e.stopPropagation()
                                                            hideOnboardingWidgetForever()
                                                        }}
                                                        className="bg-gray-600 hover:bg-gray-500 rounded p-1"
                                                    >
                                                        Hide
                                                    </button>
                                                )}
                                            </div>
                                            <div className="flex items-center justify-between gap-2">
                                                <span className="text-cyan">
                                                    {onboarding.data?.progress.completed} of{' '}
                                                    {onboarding.data?.progress.total} done
                                                </span>

                                                {!onboarding.data.isComplete && (
                                                    <RiArrowRightSLine
                                                        size={24}
                                                        className="shrink-0"
                                                    />
                                                )}
                                            </div>
                                            <div className="relative h-2 mt-2 bg-gray-600 rounded-sm">
                                                <div
                                                    className="absolute inset-0 h-2 rounded-sm bg-cyan"
                                                    style={{
                                                        width: `${
                                                            (onboarding.data?.progress.percent ??
                                                                0) * 100
                                                        }%`,
                                                    }}
                                                ></div>
                                            </div>
                                        </motion.div>
                                    )}
                                </AnimatePresence>
                            }
                            name={user?.name}
                            email={user?.email}
                        >
                            {sidebar}
                        </DefaultContent>
                    ))}
            </motion.aside>

            <main id="mainScrollArea" className="p-12 bg-black custom-gray-scroll">
                <div className="relative h-full max-w-screen-xl mx-auto">
                    <LayoutContextProvider overlayContainer={overlayContainer}>
                        <div className="relative min-h-full pb-24">
                            {children}
                            <div ref={overlayContainer}></div>
                        </div>
                    </LayoutContextProvider>
                </div>
            </main>

            <motion.aside
                variants={{
                    expanded: { opacity: 0 },
                    collapsed: { opacity: 0 },
                    popout: { opacity: [0, 1] },
                }}
                animate={layout}
                className="bg-gray-800 custom-gray-scroll"
            >
                {layout === 'popout' && popoutContents}
            </motion.aside>
        </motion.div>
    )
}

export default DesktopLayout

function DefaultContent({
    children,
    onboarding,
    name,
    email,
}: PropsWithChildren<{ onboarding?: ReactNode; name?: string; email?: string }>) {
    const { addAccount } = useAccountContext()

    return (
        <>
            <div className="flex items-center justify-between mb-4">
                <h5 className="uppercase">Assets & Debts</h5>
                <Tooltip content="Add account" placement="bottom">
                    <Button
                        className="-mt-1"
                        variant="icon"
                        onClick={addAccount}
                        data-testid="add-account-button"
                    >
                        <RiAddFill className="w-6 h-6" />
                    </Button>
                </Tooltip>
            </div>

            {/* Margin and padding offsets pin the scrollbar to the right edge of container */}
            <div className="relative pr-4 -mr-4 grow custom-gray-scroll">
                {children}
                <div className="sticky bottom-0 w-full h-16 pointer-events-none bg-gradient-to-t from-gray-800" />
            </div>

            {onboarding && onboarding}

            <div className="flex items-center justify-between">
                <div className="text-base">
                    <p data-testid="user-name">{name ?? ''}</p>
                    <p className="text-gray-100">{email ?? ''}</p>
                </div>
                <MenuPopover isHeader={false} icon={<RiMore2Fill />} />
            </div>
        </>
    )
}
