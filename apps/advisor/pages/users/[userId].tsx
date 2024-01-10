import Link from 'next/link'
import { useRouter } from 'next/router'
import { type ReactNode, useState, Fragment, useMemo } from 'react'
import { RiArrowLeftSLine, RiFileCopyLine } from 'react-icons/ri'
import { withPageAuthRequired } from '@auth0/nextjs-auth0'
import { Button, LoadingSpinner, RTEditor } from '@maybe-finance/design-system'
import Layout from '../../components/Layout'
import Users from '../../components/UserList'
import EditUser from '../../components/EditUser'
import { ConversationPreview, ConversationStatusIndicator } from '../../components/Conversations'
import { type RouterOutput, trpc } from '../../lib/trpc'
import cn from 'classnames'
import { ATAUtil, Geo, NumberUtil, type SharedType } from '@maybe-finance/shared'
import { Tab } from '@headlessui/react'
import type { ConversationNote, User } from '@prisma/client'
import { taxMap, goalsMap, householdMap, maybeGoalsMap } from '../../lib/util'
import StarterKit from '@tiptap/starter-kit'
import { useEditor } from '@tiptap/react'
import { DateTime } from 'luxon'
import { BrowserUtil } from '@maybe-finance/client/shared'
import { type ColumnDef, flexRender, getCoreRowModel, useReactTable } from '@tanstack/react-table'

export const getServerSideProps = withPageAuthRequired()

const tabs = [
    { name: 'Profile', href: 'profile' },
    { name: 'Investments', href: 'financials' },
    { name: 'My Conversations', href: 'conversations' },
    { name: 'My Notes', href: 'advisor-notes' },
]

type PanelContentProps = {
    user: User
}

function UserProfile({
    user: {
        state,
        country,
        household,
        maybeGoals,
        maybeGoalsDescription,
        goals,
        userNotes,
        auth0Id,
        taxStatus,
        grossIncome,
        incomeType,
        dependents,
        riskAnswers,
    },
}: PanelContentProps) {
    const riskProfile = ATAUtil.calcRiskProfile(
        ATAUtil.riskQuestions,
        (riskAnswers ?? []) as SharedType.RiskAnswer[]
    )

    return (
        <div>
            <h6 className="mb-4">User Info</h6>
            <dl className="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2">
                <Data
                    title="Location"
                    value={`${Geo.states.find((s) => s.code === state)?.name}, ${
                        Geo.countries.find((c) => c.code === country)?.name
                    }`}
                />

                <Data title="Auth0 ID" value={auth0Id} />
                <Data title="Household" value={householdMap[household!]} />
                <Data title="Number of Kids" value={dependents ?? 'Unknown'} />
                <Data title="Tax Status" value={taxStatus ? taxMap[taxStatus] : 'Unknown'} />
                <Data
                    title="Gross Income"
                    value={
                        grossIncome ? NumberUtil.format(grossIncome, 'short-currency') : 'Unknown'
                    }
                />
                <Data title="Income Type" value={incomeType ?? 'Unknown'} />
                <Data
                    title='Risk Tolerance (5 is "most risky")'
                    value={riskProfile ? `${riskProfile.score} / 5` : 'Unknown'}
                />
            </dl>

            <h6 className="mt-8 mb-4">Goals</h6>
            <dl className="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2">
                <Data
                    title="Maybe Goals"
                    value={
                        <div className="space-y-3 my-4">
                            <ul className="list-disc ml-4">
                                {maybeGoals.map((mg) => (
                                    <li key={mg}>{maybeGoalsMap[mg]}</li>
                                ))}
                            </ul>
                            {maybeGoalsDescription && <p>{maybeGoalsDescription}</p>}
                        </div>
                    }
                />

                <Data
                    title="Ask My Advisor Goals"
                    value={
                        <div className="my-4 space-y-3">
                            <ul className="list-disc ml-4">
                                {goals
                                    .filter((g) => !!g)
                                    .map((g) => (
                                        <li key={g}>{goalsMap[g] ? goalsMap[g] : g}</li>
                                    ))}
                            </ul>
                            {userNotes && <p>{userNotes}</p>}
                        </div>
                    }
                />
            </dl>
        </div>
    )
}

function UserConversations() {
    const router = useRouter()
    const conversations = trpc.advisor.users.getConversations.useQuery(+router.query.userId!, {
        enabled: !!router.query.userId,
    })

    if (conversations.isLoading)
        return <p className="text-gray-100 animate-pulse text-base">Loading conversations...</p>
    if (conversations.isError)
        return <p className="text-red text-base">Failed to load conversations</p>
    if (!conversations.data.length)
        return (
            <p className="text-gray-100 text-base">
                You have not had any conversations with this user yet
            </p>
        )

    return (
        <>
            {conversations.data.map((conversation) => (
                <div
                    key={conversation.id}
                    className="rounded border border-gray-700 p-2 sm:p-4 flex items-center justify-between my-6"
                >
                    <div>
                        <div className="flex items-center gap-4">
                            <h6>{conversation.title}</h6>
                            <ConversationStatusIndicator conversation={conversation} />
                        </div>
                        <time
                            dateTime={conversation.createdAt.toISOString()}
                            className="shrink-0 whitespace-nowrap text-sm text-gray-100"
                        >
                            {conversation.createdAt.toLocaleString()}
                        </time>
                        <ConversationPreview conversation={conversation} />
                    </div>

                    <Link href={`/conversations/${conversation.id}`} legacyBehavior passHref>
                        <Button>Go to Conversation</Button>
                    </Link>
                </div>
            ))}
        </>
    )
}

function AdvisorNote({ note }: { note: ConversationNote }) {
    const editor = useEditor(
        {
            extensions: [
                StarterKit.configure({
                    heading: {
                        levels: [1],
                    },
                }),
            ],
            editable: false,
            content: note.body,
            editorProps: {
                attributes: {
                    class: 'flex-1 prose prose-light prose-sm dark:prose-invert prose-headings:text-lg leading-tight focus:outline-none',
                },
            },
        },
        [note]
    )

    return <RTEditor editor={editor} hideControls />
}

function AdvisorNotes() {
    const router = useRouter()
    const notes = trpc.advisor.users.getNotes.useQuery(+router.query.userId!, {
        enabled: !!router.query.userId,
    })

    if (notes.isLoading)
        return <p className="text-gray-100 animate-pulse text-base">Loading notes...</p>
    if (notes.isError) return <p className="text-red text-base">Failed to load notes</p>
    if (!notes.data.length)
        return (
            <p className="text-gray-100 text-base">
                You have not left any notes for this user yet.
            </p>
        )

    return (
        <>
            {notes.data.map((note) => (
                <div key={note.id} className="rounded border border-gray-600 my-6">
                    <div className="bg-gray-700 px-2 text-base flex items-center justify-between rounded-t">
                        <p>
                            Note from{' '}
                            {DateTime.fromJSDate(note.createdAt, { zone: 'utc' }).toFormat(
                                'MMM dd, yyyy'
                            )}
                        </p>
                        <Link href={`/conversations/${note.conversationId}`}>
                            <Button variant="link">Open conversation</Button>
                        </Link>
                    </div>
                    <AdvisorNote note={note} />
                </div>
            ))}
        </>
    )
}

function HoldingsTable({ data }: { data: any }) {
    const columns = useMemo<
        ColumnDef<
            RouterOutput['advisor']['users']['getHoldings']['holdings'][number][number][number]
        >[]
    >(
        () => [
            {
                header: 'Security',
                accessorFn(row) {
                    return `${row.symbol ? `(${row.symbol})` : ''} ${row.security_name}`
                },
                cell({ getValue }) {
                    return (
                        <span className="whitespace-nowrap max-w-[300px] block truncate">
                            {getValue() as any}
                        </span>
                    )
                },
            },
            {
                header: 'Quantity',
                accessorFn(row) {
                    return NumberUtil.format(row.quantity, 'decimal')
                },
            },
            {
                header: 'Value',
                accessorFn(row) {
                    return NumberUtil.format(row.value, 'currency')
                },
            },
            {
                header: 'Cost Basis',
                accessorFn(row) {
                    return NumberUtil.format(row.cost_basis, 'currency')
                },
            },
            {
                header: 'Cost Basis / share',
                accessorFn(row) {
                    return NumberUtil.format(row.cost_basis_per_share, 'currency')
                },
            },
            {
                header: 'Price',
                accessorFn(row) {
                    return NumberUtil.format(row.price, 'currency')
                },
            },
            {
                header: 'Price Prev',
                accessorFn(row) {
                    return NumberUtil.format(row.price_prev, 'currency')
                },
            },
        ],
        []
    )
    const table = useReactTable({
        columns,
        data,
        getCoreRowModel: getCoreRowModel(),
    })

    return (
        <table style={{ width: table.getCenterTotalSize() }}>
            <thead>
                {table.getHeaderGroups().map((headerGroup) => (
                    <tr key={headerGroup.id}>
                        {headerGroup.headers.map((header) => (
                            <th
                                key={header.id}
                                colSpan={header.colSpan}
                                className="text-sm text-left p-1"
                                style={{
                                    width: header.getSize() + 50,
                                }}
                            >
                                {flexRender(header.column.columnDef.header, header.getContext())}
                            </th>
                        ))}
                    </tr>
                ))}
            </thead>

            <tbody>
                {table.getRowModel().rows.map((row) => (
                    <tr key={row.id} className="text-base">
                        {row.getVisibleCells().map((cell) => (
                            <td key={cell.id} className="p-1">
                                {flexRender(cell.column.columnDef.cell, cell.getContext())}
                            </td>
                        ))}
                    </tr>
                ))}
            </tbody>
        </table>
    )
}

function Holdings({ userId }: { userId: User['id'] }) {
    const holdings = trpc.advisor.users.getHoldings.useQuery(userId)

    if (holdings.isLoading)
        return <p className="text-gray-100 animate-pulse text-base">Loading holdings...</p>
    if (holdings.isError) return <p className="text-red text-base">Failed to load holdings</p>

    return (
        <div>
            <div className="flex items-center justify-between">
                <h4>Holdings by institution</h4>
                <div className="flex items-center gap-1">
                    <span className="text-base text-gray-50">Copy all as CSV</span>
                    <Button
                        variant="icon"
                        onClick={() => BrowserUtil.copyToClipboard(holdings.data.csv)}
                    >
                        <RiFileCopyLine className="text-cyan" />
                    </Button>
                </div>
            </div>
            <div>
                {Object.entries(holdings.data.holdings).map(([connection, accountHoldings]) => (
                    <div key={connection} className="space-y-3 my-8">
                        <h6>{connection}</h6>
                        {Object.entries(accountHoldings).map(([account, holdings]) => (
                            <div key={account} className="rounded border border-gray-600">
                                <div className="bg-gray-700 p-3 text-base flex items-center justify-between rounded-t">
                                    <p>{account}</p>
                                </div>
                                <div className="p-2 overflow-x-auto">
                                    <HoldingsTable data={holdings} />
                                </div>
                            </div>
                        ))}
                    </div>
                ))}
            </div>
        </div>
    )
}

export default function UserPage() {
    const router = useRouter()

    const [isEditing, setIsEditing] = useState(false)

    const currentTabIdx = tabs.findIndex((t) => t.href === router.asPath.split('#').at(-1))

    const user = trpc.advisor.users.get.useQuery(+router.query.userId!, {
        enabled: !!router.query.userId,
    })

    if (user.isLoading) {
        return (
            <div className="h-full flex flex-col items-center justify-center">
                <LoadingSpinner />
            </div>
        )
    }

    if (user.isError) {
        return (
            <div className="h-full flex flex-col items-center justify-center">
                <h3 className="text-lg font-medium text-white">Not Found</h3>
                <p className="mt-1 text-base text-gray-100">
                    We can&apos;t find that conversation.
                </p>
            </div>
        )
    }

    const { picture, name } = user.data

    return (
        <>
            <EditUser user={user.data} isOpen={isEditing} onClose={() => setIsEditing(false)} />
            <main className="relative z-0 flex-1 overflow-y-auto focus:outline-none xl:order-last">
                <nav
                    className="lg:hidden mt-6 flex items-start px-2 sm:px-6 lg:px-8 xl:hidden"
                    aria-label="Breadcrumb"
                >
                    <Link
                        href="/users"
                        className="inline-flex items-center text-sm font-medium p-1 rounded text-gray-100 hover:bg-gray-600"
                    >
                        <RiArrowLeftSLine
                            className="h-5 w-5 text-gray-100 mr-1"
                            aria-hidden="true"
                        />
                        <span>Directory</span>
                    </Link>
                </nav>

                <article>
                    {/* Profile header */}
                    <div>
                        <div className="mx-auto mt-8 max-w-5xl px-4 sm:px-6 lg:px-8">
                            <div className="sm:flex sm:items-end sm:space-x-5">
                                <div className="sm:flex justify-between items-center w-full">
                                    <img
                                        className="h-16 w-16 rounded-full ring-4 ring-white sm:h-18 sm:w-18"
                                        src={picture ?? ''}
                                        alt="profile picture"
                                    />
                                    <div>
                                        <Button
                                            className="mt-6 sm:mt-0"
                                            variant="secondary"
                                            onClick={() => setIsEditing(true)}
                                        >
                                            Edit User
                                        </Button>
                                    </div>
                                </div>
                                <div className="mt-6 sm:flex sm:min-w-0 sm:flex-1 sm:items-center sm:justify-end sm:space-x-6 sm:pb-1">
                                    <div className="mt-6 min-w-0 flex-1 sm:hidden 2xl:block">
                                        <h1 className="truncate text-2xl font-bold text-white">
                                            {name}
                                        </h1>
                                    </div>
                                </div>
                            </div>
                            <div className="mt-6 hidden min-w-0 flex-1 sm:block 2xl:hidden">
                                <h1 className="truncate text-2xl font-bold text-white">{name}</h1>
                            </div>
                        </div>
                    </div>

                    {/* Tabs */}

                    <div className="mt-6 sm:mt-2 2xl:mt-5">
                        <Tab.Group
                            selectedIndex={currentTabIdx > 0 ? currentTabIdx : 0}
                            onChange={(idx) => {
                                router.push(`/users/${router.query.userId}#${tabs[idx].href}`)
                            }}
                        >
                            <div className="border-b border-gray-600 overflow-x-auto">
                                <Tab.List className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
                                    <div className="-mb-px flex space-x-8 focus-visible:outline-none">
                                        {tabs.map((tab, idx) => (
                                            <Tab
                                                key={idx}
                                                className={({ selected }) =>
                                                    cn(
                                                        selected
                                                            ? 'border-cyan-500 text-white'
                                                            : 'border-transparent text-gray-200 hover:text-white hover:border-cyan',
                                                        'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm focus-visible:outline-none'
                                                    )
                                                }
                                            >
                                                {tab.name}
                                            </Tab>
                                        ))}
                                    </div>
                                </Tab.List>
                            </div>
                            <Tab.Panels className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8 py-6">
                                <Tab.Panel>
                                    <UserProfile user={user.data} />
                                </Tab.Panel>

                                <Tab.Panel>
                                    <Holdings userId={user.data.id} />
                                </Tab.Panel>

                                <Tab.Panel>
                                    <UserConversations />
                                </Tab.Panel>

                                <Tab.Panel>
                                    <AdvisorNotes />
                                </Tab.Panel>
                            </Tab.Panels>
                        </Tab.Group>
                    </div>
                </article>
            </main>
        </>
    )
}

UserPage.getLayout = (page) => (
    <Layout>
        <Users>{page}</Users>
    </Layout>
)

function Data({ title, value }: { title: string; value: ReactNode }) {
    return (
        <div className="sm:col-span-1">
            <dt className="text-sm font-medium text-gray-100">{title}</dt>
            <dd className="mt-1 text-sm text-white">{value}</dd>
        </div>
    )
}
