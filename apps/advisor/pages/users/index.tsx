import { withPageAuthRequired } from '@auth0/nextjs-auth0'
import { RiUserSearchLine } from 'react-icons/ri'
import UserList from '../../components/UserList'
import Layout from '../../components/Layout'
import UserSearch from '../../components/UserSearch'
import { useState } from 'react'
import { trpc } from '../../lib/trpc'
import Link from 'next/link'

// No typings available for this module
// eslint-disable-next-line @typescript-eslint/no-var-requires
const fuzzysearch = require('fuzzysearch')

export const getServerSideProps = withPageAuthRequired()

export default function UsersPage() {
    const users = trpc.advisor.users.getAll.useQuery()
    const [query, setQuery] = useState('')

    const userList = (users.data ?? []).filter((u) =>
        fuzzysearch(query.toLowerCase(), u.name?.toLowerCase())
    )

    return (
        <div className="h-full">
            <div className="relative px-4 lg:hidden">
                <UserSearch onChange={setQuery} />
            </div>
            {query ? (
                <div>
                    <ul role="list" className="text-base p-4">
                        {userList.length ? (
                            userList.map((user) => (
                                <Link
                                    key={user.id}
                                    href={`/users/${user.id}`}
                                    onClick={() => setQuery('')}
                                    className="flex items-center gap-3 p-4 rounded cursor-pointer hover:bg-gray-600"
                                >
                                    <img
                                        className="w-8 h-8 rounded-full"
                                        src={user.picture ?? ''}
                                        alt={user.name ?? 'profile'}
                                    />

                                    <div>
                                        <span>{user.name}</span>
                                        <span className="text-gray-100 block text-sm -mt-1">
                                            {user.email}
                                        </span>
                                    </div>
                                </Link>
                            ))
                        ) : (
                            <div className="px-4 py-2">
                                <p className="text-gray-50">No users found</p>
                            </div>
                        )}
                    </ul>
                </div>
            ) : (
                <div className="h-full flex flex-col items-center justify-center">
                    <RiUserSearchLine className="h-10 w-10 text-gray-100" />
                    <h3 className="mt-2 text-base font-medium text-white">Users</h3>
                    <p className="mt-1 text-sm text-gray-100">Select a user to see their profile</p>
                </div>
            )}
        </div>
    )
}

UsersPage.getLayout = (page) => (
    <Layout>
        <UserList>{page}</UserList>
    </Layout>
)
