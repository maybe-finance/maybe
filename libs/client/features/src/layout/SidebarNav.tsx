import classNames from 'classnames'
import Link from 'next/link'
import { useRouter } from 'next/router'
import { RiBriefcaseLine, RiPieChartLine } from 'react-icons/ri'

type SidebarNavProps = {
    accountsNotification?: 'error' | 'update' | null
}

export function SidebarNav({ accountsNotification }: SidebarNavProps) {
    const router = useRouter()

    return (
        <nav className="flex flex-col space-y-1">
            <Link
                href="/"
                className={classNames(
                    'flex items-center space-x-2 h-8 hover:bg-gray-600 rounded pl-2',
                    router.pathname === '/' ? 'bg-gray-500' : ''
                )}
            >
                <RiPieChartLine
                    className={classNames('h-5 w-5', router.pathname !== '/' && 'text-gray-100')}
                />
                <span className="text-base">Net Worth</span>
            </Link>
            <Link
                href="/accounts"
                className={classNames(
                    'flex items-center space-x-2 h-8 hover:bg-gray-600 rounded pl-2',
                    router.pathname === '/accounts' ? 'bg-gray-500' : ''
                )}
            >
                <span className="inline-block relative">
                    <RiBriefcaseLine
                        className={classNames(
                            'h-5 w-5',
                            router.pathname !== '/accounts' && 'text-gray-100'
                        )}
                    />
                    {accountsNotification && (
                        <span
                            className={classNames(
                                'absolute top-0 right-0 block h-[5px] w-[5px] transform translate-x-1/2 rounded-full ring-2 ring-gray-600',
                                accountsNotification === 'update' ? 'bg-cyan' : 'bg-red'
                            )}
                        />
                    )}
                </span>
                <span className="text-base">Accounts</span>
            </Link>
        </nav>
    )
}

export default SidebarNav
