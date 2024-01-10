import Link from 'next/link'
import { useRouter } from 'next/router'
import { Fragment, useRef, useState } from 'react'
import {
    RiUserAddLine,
    RiUserReceivedLine,
    RiCheckboxCircleLine,
    RiRefreshLine,
    RiArrowDownSLine,
    RiArrowUpSLine,
} from 'react-icons/ri'
import toast from 'react-hot-toast'
import { withPageAuthRequired } from '@auth0/nextjs-auth0'
import { Button, LoadingSpinner, RTEditor } from '@maybe-finance/design-system'
import { ATAUtil } from '@maybe-finance/shared'
import Conversations from '../../components/Conversations'
import ConversationComponent from '../../components/Conversation'
import ConversationUserDetails from '../../components/ConversationUserDetails'
import Layout from '../../components/Layout'
import AdvisorMessageInput from '../../components/AdvisorMessageInput'
import { trpc } from '../../lib/trpc'
import { Disclosure, Transition } from '@headlessui/react'
import cn from 'classnames'
import { useEditor } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import Placeholder from '@tiptap/extension-placeholder'
import type { Conversation } from '@prisma/client'
import { useLastUpdated } from '@maybe-finance/client/shared'

type AdvisorNotesProps = {
    conversationId: Conversation['id']
}

function AdvisorNotes({ conversationId }: AdvisorNotesProps) {
    const utils = trpc.useContext()
    const note = trpc.advisor.conversations.getNote.useQuery(conversationId, {
        staleTime: Infinity,
    })

    const upsertNote = trpc.advisor.conversations.upsertNote.useMutation({
        onSuccess() {
            toast.success('Saved notes')
            utils.advisor.conversations.getNote.invalidate()
        },
        onError() {
            toast.success('Did not save note')
        },
    })

    const lastUpdated = useLastUpdated(note.data?.updatedAt, false)

    const editor = useEditor(
        {
            extensions: [
                StarterKit.configure({
                    heading: {
                        levels: [1],
                    },
                }),
                Placeholder.configure({
                    placeholder: 'Enter private advisor note...',
                    emptyEditorClass: 'placeholder text-gray-100 caret-white',
                }),
            ],
            content: note.data?.body,
            editorProps: {
                attributes: {
                    class: 'flex-1 prose prose-light prose-sm dark:prose-invert prose-headings:text-lg leading-tight focus:outline-none',
                },
            },
        },
        [note.data]
    )

    if (!editor) return <p className="ml-2 text-red text-sm">Unable to load editor</p>

    return (
        <div className="space-y-2">
            <RTEditor editor={editor} className="min-h-[180px]" />

            <div className="flex justify-between items-center">
                <span className="text-gray-50 text-sm ml-2">Last saved: {lastUpdated}</span>
                <Button
                    disabled={editor.isEmpty}
                    onClick={() => {
                        upsertNote.mutate({
                            conversationId,
                            body: editor.getHTML(),
                        })
                    }}
                >
                    Save
                </Button>
            </div>
        </div>
    )
}

export const getServerSideProps = withPageAuthRequired()

export default function ConversationPage() {
    const router = useRouter()
    const utils = trpc.useContext()

    const conversationEndRef = useRef<HTMLDivElement | null>(null)

    const [value, setValue] = useState<string | null>(null)

    // ToDo: figure out auto-scrolling behavior
    const scrollToBottom = () => {
        conversationEndRef.current?.scrollIntoView({ behavior: 'smooth' })
    }

    const conversationQuery = trpc.advisor.conversations.get.useQuery(+router.query.id!, {
        enabled: !!router.query.id,
    })

    const meQuery = trpc.users.me.useQuery()

    const updateConversation = trpc.advisor.conversations.update.useMutation({
        async onSuccess() {
            await utils.advisor.conversations.invalidate()
        },
    })

    const addAdvisor = trpc.advisor.conversationAdvisors.create.useMutation({
        async onSuccess() {
            toast.success('Joined conversation')
            await utils.advisor.conversations.invalidate()
        },
    })

    const removeAdvisor = trpc.advisor.conversationAdvisors.delete.useMutation({
        async onSuccess() {
            toast.success('Left conversation')
            await utils.advisor.conversations.invalidate()
        },
    })

    const sendMessage = trpc.messages.create.useMutation({
        async onSuccess() {
            toast.success('Message sent')
            await utils.advisor.conversations.invalidate()
        },
    })

    if (conversationQuery.isLoading || meQuery.isLoading) {
        return (
            <div className="h-full flex flex-col items-center justify-center">
                <LoadingSpinner />
            </div>
        )
    }

    if (!conversationQuery.data || !meQuery.data) {
        return (
            <div className="h-full flex flex-col items-center justify-center">
                <h3 className="text-lg font-medium text-white">Not Found</h3>
                <p className="mt-1 text-base text-gray-100">
                    We can&apos;t find that conversation.
                </p>
            </div>
        )
    }

    const conversation = conversationQuery.data
    const me = meQuery.data
    const advisor = me.advisor

    const inConversation = conversation.advisors.some((a) => a.advisorId === advisor?.id)

    return (
        <div className="h-full flex">
            <section className="h-full flex-1 flex flex-col">
                {/* Top section */}
                <div className="shrink-0 divide-y divide-gray-700 border-b border-gray-700 bg-gray-800">
                    {/* Mobile navbar */}
                    <nav className="px-4 py-1 sm:px-6 lg:hidden">
                        <Link href="/conversations" className="block py-1 text-base text-gray-50">
                            &larr; Inbox
                        </Link>
                    </nav>

                    {/* Toolbar*/}
                    <div className="h-16 flex flex-col justify-center px-4 sm:px-6">
                        <div className="flex items-center justify-between space-x-3">
                            <div className="flex items-center space-x-3">
                                {advisor &&
                                    (inConversation ? (
                                        <Button
                                            leftIcon={<RiUserReceivedLine size={16} />}
                                            variant="secondary"
                                            disabled={
                                                removeAdvisor.isLoading ||
                                                conversation.status === 'closed'
                                            }
                                            onClick={() =>
                                                removeAdvisor.mutate({
                                                    conversationId: conversation.id,
                                                    advisorId: advisor.id,
                                                })
                                            }
                                        >
                                            Leave
                                        </Button>
                                    ) : (
                                        <Button
                                            leftIcon={<RiUserAddLine size={16} />}
                                            variant="secondary"
                                            disabled={
                                                addAdvisor.isLoading ||
                                                conversation.status === 'closed'
                                            }
                                            onClick={() =>
                                                addAdvisor.mutate({
                                                    conversationId: conversation.id,
                                                    advisorId: advisor.id,
                                                })
                                            }
                                        >
                                            Join
                                        </Button>
                                    ))}
                            </div>
                            <div className="flex items-center space-x-3">
                                {conversation.status === 'open' ? (
                                    <Button
                                        leftIcon={<RiCheckboxCircleLine size={16} />}
                                        variant="secondary"
                                        disabled={updateConversation.isLoading}
                                        onClick={() =>
                                            updateConversation.mutate(
                                                {
                                                    id: conversation.id,
                                                    status: 'closed',
                                                },
                                                {
                                                    onSuccess() {
                                                        toast.success('Closed conversation')
                                                    },
                                                }
                                            )
                                        }
                                    >
                                        Close
                                    </Button>
                                ) : (
                                    <Button
                                        leftIcon={<RiRefreshLine size={16} />}
                                        variant="secondary"
                                        disabled={updateConversation.isLoading}
                                        onClick={() =>
                                            updateConversation.mutate(
                                                {
                                                    id: conversation.id,
                                                    status: 'open',
                                                },
                                                {
                                                    onSuccess() {
                                                        toast.success('Re-opened conversation')
                                                    },
                                                }
                                            )
                                        }
                                    >
                                        Re-open
                                    </Button>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* Message header */}
                    <div className="px-4 py-4 sm:px-6">
                        <h1
                            id="message-heading"
                            className="text-xl font-sans font-medium text-gray-900"
                        >
                            {conversation.title}
                        </h1>
                        <p className="mt-1 truncate text-sm text-gray-100">
                            Started by{' '}
                            <span className="text-gray-50">{conversation.user.name}</span> on{' '}
                            <time
                                dateTime={conversation.createdAt.toISOString()}
                                className="text-gray-50"
                            >
                                {conversation.createdAt.toLocaleString()}
                            </time>
                        </p>
                    </div>
                </div>

                <div className="relative px-4 sm:px-6 py-4 text-base bg-gray-800 border-b border-b-gray-700">
                    <Disclosure>
                        {({ open }) => (
                            <>
                                <Disclosure.Button
                                    className={cn(
                                        'flex items-center justify-between w-full text-cyan px-2'
                                    )}
                                >
                                    <div className="text-left">
                                        <span>Advisor Notes</span>
                                        {open && (
                                            <span className="text-gray-50 block text-sm">
                                                These notes are only visible to you
                                            </span>
                                        )}
                                    </div>
                                    <Button variant="icon">
                                        {open ? (
                                            <RiArrowUpSLine className="text-cyan" />
                                        ) : (
                                            <RiArrowDownSLine className="text-cyan" />
                                        )}
                                    </Button>
                                </Disclosure.Button>
                                <Transition
                                    as={Fragment}
                                    enter="transition duration-100 ease-out"
                                    enterFrom="transform scale-95 opacity-0"
                                    enterTo="transform scale-100 opacity-100"
                                    leave="transition duration-75 ease-out"
                                    leaveFrom="transform scale-100 opacity-100"
                                    leaveTo="transform scale-95 opacity-0"
                                >
                                    <Disclosure.Panel className="mt-4 ">
                                        <AdvisorNotes conversationId={conversation.id} />
                                    </Disclosure.Panel>
                                </Transition>
                            </>
                        )}
                    </Disclosure>
                </div>

                <div className="px-6 pt-6 pb-4 flex-1 overflow-y-scroll">
                    <ConversationComponent me={me} conversation={conversation} />
                    <div ref={conversationEndRef} />
                </div>

                <div className="px-6 pt-2 pb-6 shrink-0">
                    <AdvisorMessageInput
                        conversationId={conversation.id}
                        onSubmit={({ body, media }) => {
                            return sendMessage.mutateAsync({
                                conversationId: conversation.id,
                                type: media ? ATAUtil.mimeToMessageType(media.type) : 'text',
                                body,
                                mediaSrc: media?.key,
                            })
                        }}
                    />
                </div>
            </section>

            <aside className="hidden h-full overflow-y-auto shrink-0 bg-gray-800 border-l border-gray-700 w-80 lg:block xl:w-96">
                <ConversationUserDetails conversation={conversation} />
            </aside>
        </div>
    )
}

ConversationPage.getLayout = (page) => (
    <Layout>
        <Conversations>{page}</Conversations>
    </Layout>
)
