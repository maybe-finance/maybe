import { Fragment, useState } from 'react'
import Link from 'next/link'
import { useUser } from '@auth0/nextjs-auth0/client'
import { Dialog, Transition } from '@headlessui/react'
import { Menu } from '@maybe-finance/design-system'
import {
    RiSettings3Line as SettingsIcon,
    RiShutDownLine as LogoutIcon,
    RiCloseLine,
    RiMenuLine,
    RiInboxLine,
    RiUserSearchLine,
} from 'react-icons/ri'

const navigation = [
    { name: 'Inbox', href: '/', icon: RiInboxLine },
    { name: 'Directory', href: '/users', icon: RiUserSearchLine },
]

export default function Layout({ children }) {
    const { user } = useUser()

    const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

    return (
        <div className="flex h-screen">
            <Transition.Root show={mobileMenuOpen} as={Fragment}>
                <Dialog as="div" className="relative z-40 lg:hidden" onClose={setMobileMenuOpen}>
                    <Transition.Child
                        as={Fragment}
                        enter="transition-opacity ease-linear duration-300"
                        enterFrom="opacity-0"
                        enterTo="opacity-100"
                        leave="transition-opacity ease-linear duration-300"
                        leaveFrom="opacity-100"
                        leaveTo="opacity-0"
                    >
                        <div className="fixed inset-0 bg-gray-600 bg-opacity-75" />
                    </Transition.Child>

                    <div className="fixed inset-0 z-40 flex">
                        <Transition.Child
                            as={Fragment}
                            enter="transition ease-in-out duration-300 transform"
                            enterFrom="-translate-x-full"
                            enterTo="translate-x-0"
                            leave="transition ease-in-out duration-300 transform"
                            leaveFrom="translate-x-0"
                            leaveTo="-translate-x-full"
                        >
                            <Dialog.Panel className="relative flex w-full max-w-xs flex-1 flex-col bg-gray-800 focus:outline-none">
                                <Transition.Child
                                    as={Fragment}
                                    enter="ease-in-out duration-300"
                                    enterFrom="opacity-0"
                                    enterTo="opacity-100"
                                    leave="ease-in-out duration-300"
                                    leaveFrom="opacity-100"
                                    leaveTo="opacity-0"
                                >
                                    <div className="absolute top-0 right-0 -mr-12 pt-4">
                                        <button
                                            type="button"
                                            className="ml-1 flex h-10 w-10 items-center justify-center rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
                                            onClick={() => setMobileMenuOpen(false)}
                                        >
                                            <span className="sr-only">Close sidebar</span>
                                            <RiCloseLine
                                                className="h-6 w-6 text-white"
                                                aria-hidden="true"
                                            />
                                        </button>
                                    </div>
                                </Transition.Child>
                                <div className="pt-5 pb-4">
                                    <div className="flex flex-shrink-0 items-center px-4">
                                        <img
                                            src="/assets/maybe.svg"
                                            alt="Maybe Finance Logo"
                                            height={36}
                                            width={36}
                                        />
                                    </div>
                                    <nav aria-label="Sidebar" className="mt-5">
                                        <div className="space-y-1 px-2">
                                            {navigation.map((item) => (
                                                <a
                                                    key={item.name}
                                                    href={item.href}
                                                    className="group flex items-center rounded-md p-2 text-base font-medium text-gray-100 hover:bg-gray-700 hover:text-gray-50"
                                                >
                                                    <item.icon
                                                        className="mr-4 h-6 w-6 text-gray-100 group-hover:text-gray-50"
                                                        aria-hidden="true"
                                                    />
                                                    {item.name}
                                                </a>
                                            ))}
                                        </div>
                                    </nav>
                                </div>
                                <div className="flex shrink-0 border-t border-gray-200 p-4">
                                    <Link href="/settings" className="group flex items-center">
                                        <div>
                                            <img
                                                className="inline-block h-10 w-10 rounded-full"
                                                src={user?.picture ?? ''}
                                                alt=""
                                            />
                                        </div>
                                        <div className="ml-3">
                                            <p className="text-base font-medium text-white group-hover:text-gray-900">
                                                {user?.name}
                                            </p>
                                            <p className="text-sm font-medium text-gray-100 group-hover:text-gray-50">
                                                Account Settings
                                            </p>
                                        </div>
                                    </Link>
                                </div>
                            </Dialog.Panel>
                        </Transition.Child>
                        <div className="w-14 flex-shrink-0" aria-hidden="true">
                            {/* Force sidebar to shrink to fit close icon */}
                        </div>
                    </div>
                </Dialog>
            </Transition.Root>

            {/* Static sidebar for desktop */}
            <div className="hidden lg:flex lg:flex-shrink-0 lg:border-r lg:border-gray-700">
                <div className="flex w-20 flex-col">
                    <div className="flex min-h-0 flex-1 flex-col bg-gray-800">
                        <div className="flex-1">
                            <div className="px-4 py-6 flex items-center justify-center">
                                <Link href="/">
                                    <img
                                        src="/assets/maybe.svg"
                                        alt="Maybe Finance Logo"
                                        height={36}
                                        width={36}
                                    />
                                </Link>
                            </div>
                            <nav
                                aria-label="Sidebar"
                                className="flex flex-col items-center space-y-3 py-4"
                            >
                                {navigation.map((item) => (
                                    <Link
                                        key={item.name}
                                        href={item.href}
                                        className="flex items-center rounded-lg p-4 text-gray-100 hover:bg-gray-700"
                                    >
                                        <item.icon className="h-6 w-6" aria-hidden="true" />
                                        <span className="sr-only">{item.name}</span>
                                    </Link>
                                ))}
                            </nav>
                        </div>
                        <div className="flex justify-center shrink-0 pb-5">
                            <Menu>
                                <Menu.Button as="button">
                                    <img
                                        className="h-10 w-10 rounded-full"
                                        src={user?.picture ?? undefined}
                                        alt=""
                                    />
                                </Menu.Button>
                                <Menu.Items placement="right-end">
                                    <Menu.ItemNextLink icon={<SettingsIcon />} href="/settings">
                                        Settings
                                    </Menu.ItemNextLink>
                                    <Menu.Item icon={<LogoutIcon />} destructive>
                                        <a href="/api/auth/logout">Logout</a>
                                    </Menu.Item>
                                </Menu.Items>
                            </Menu>
                        </div>
                    </div>
                </div>
            </div>

            <div className="flex min-w-0 flex-1 flex-col overflow-hidden">
                {/* Mobile top navigation */}
                <div className="bg-gray-800 border-b border-gray-700 lg:hidden">
                    <div className="flex items-center justify-between bg-cyan-600 py-2 px-4 sm:px-6 lg:px-8">
                        <div>
                            <img
                                src="/assets/maybe.svg"
                                alt="Maybe Finance Logo"
                                height={36}
                                width={36}
                            />
                        </div>
                        <div>
                            <button
                                type="button"
                                className="-mr-3 inline-flex h-12 w-12 items-center justify-center rounded-md bg-indigo-600 text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
                                onClick={() => setMobileMenuOpen(true)}
                            >
                                <span className="sr-only">Open sidebar</span>
                                <RiMenuLine className="h-6 w-6" aria-hidden="true" />
                            </button>
                        </div>
                    </div>
                </div>

                <main className="flex-1 overflow-hidden">{children}</main>
            </div>
        </div>
    )
}
