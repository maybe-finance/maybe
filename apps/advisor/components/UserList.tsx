import { type PropsWithChildren, useState } from 'react'
import { groupBy } from 'lodash'
import { trpc } from '../lib/trpc'
import Link from 'next/link'
import UserSearch from './UserSearch'

// No typings available for this module
// eslint-disable-next-line @typescript-eslint/no-var-requires
const fuzzysearch = require('fuzzysearch')

export default function Users({ children }: PropsWithChildren) {
    const users = trpc.advisor.users.getAll.useQuery()
    const [query, setQuery] = useState('')

    const userList = (users.data ?? []).filter((u) =>
        fuzzysearch(query.toLowerCase(), u.name?.toLowerCase())
    )
    const groupedUsers = groupBy(userList, (user) => user.lastName?.at(0))

    return (
        <div className="h-full flex">
            {/* Primary column */}
            <section
                aria-labelledby="primary-heading"
                className="flex h-full min-w-0 flex-1 flex-col overflow-y-auto lg:order-2"
            >
                <h1 id="primary-heading" className="sr-only">
                    User
                </h1>

                {children}
            </section>

            {/* Left sidebar (hidden on smaller screens) */}
            <aside className="hidden w-80 xl:w-96 bg-gray-800 flex-shrink-0 border-r border-gray-700 lg:order-first lg:flex lg:flex-col">
                <div className="px-6 pt-6 pb-4">
                    <h2 className="text-lg font-medium text-gray-900">Directory</h2>
                    <p className="mt-1 text-sm text-gray-100">
                        Search directory of {users.data?.length} users
                    </p>

                    <UserSearch onChange={setQuery} />
                </div>
                {/* Directory list */}
                <nav className="min-h-0 flex-1 overflow-y-auto" aria-label="Directory">
                    {Object.keys(groupedUsers).map((letter) => (
                        <div key={letter} className="relative">
                            <div className="sticky top-0 z-10 border-t border-b border-gray-600 bg-gray-700 px-6 py-1 text-sm font-medium text-gray-200">
                                <h3>{letter}</h3>
                            </div>
                            <ul role="list" className="relative z-0 divide-y divide-gray-600">
                                {groupedUsers[letter].map((user) => (
                                    <li key={user.id}>
                                        <div className="relative flex items-center space-x-3 px-6 py-5 focus-within:ring-2 focus-within:ring-inset focus-within:ring-gray-500 hover:bg-gray-700">
                                            <div className="flex-shrink-0">
                                                <img
                                                    className="h-10 w-10 rounded-full"
                                                    src={user.picture ?? ''}
                                                    alt=""
                                                />
                                            </div>
                                            <div className="min-w-0 flex-1">
                                                <Link
                                                    href={`/users/${user.id}`}
                                                    className="focus:outline-none"
                                                >
                                                    <span
                                                        className="absolute inset-0"
                                                        aria-hidden="true"
                                                    />
                                                    <p className="text-sm font-medium text-gray-900">
                                                        {user.name}
                                                    </p>
                                                    <p className="truncate text-sm text-gray-200">
                                                        {user.email}
                                                    </p>
                                                </Link>
                                            </div>
                                        </div>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    ))}
                </nav>
            </aside>
        </div>
    )
}
