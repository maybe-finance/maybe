import Link from 'next/link'
import { useRouter } from 'next/router'
import { useState } from 'react'
import { DateTime } from 'luxon'
import cn from 'classnames'
import { RiCheckLine, RiReplyFill } from 'react-icons/ri'
import { Tab } from '@maybe-finance/design-system'
import { useRichTextPreview } from '@maybe-finance/client/shared'
import type { RouterOutput } from '../lib/trpc'
import { trpc } from '../lib/trpc'

type Conversation = RouterOutput['advisor']['conversations']['getAll'][0]

const tabs: {
    label: string
    filter(conversation: Conversation): boolean
}[] = [
    { label: 'All', filter: () => true },
    { label: 'Open', filter: (c) => c.status === 'open' },
    { label: 'Closed', filter: (c) => c.status === 'closed' },
]

export default function Conversations({ children }) {
    const router = useRouter()

    const [tab, setTab] = useState(1)

    const meQuery = trpc.users.me.useQuery()

    const conversationsQuery = trpc.advisor.conversations.getAll.useQuery()
    const conversations = conversationsQuery.data ?? []

    const filteredConversations = conversations.filter(tabs[tab].filter)

    return (
        <div className="h-full flex">
            {/* Primary column */}
            <section
                aria-labelledby="primary-heading"
                className="flex h-full min-w-0 flex-1 flex-col overflow-y-auto lg:order-2"
            >
                <h1 id="primary-heading" className="sr-only">
                    Conversation
                </h1>

                {children}
            </section>

            {/* Left sidebar (hidden on smaller screens) */}
            <aside className="hidden lg:order-1 lg:block lg:flex-shrink-0">
                <div className="relative flex h-full w-80 xl:w-96 flex-col overflow-y-auto bg-gray-800 divide-y divide-gray-700 border-r border-gray-700">
                    <div className="h-16 px-6 flex flex-col justify-center">
                        <div className="flex items-baseline space-x-3">
                            <h2 className="text-xl font-bold font-display text-white">Inbox</h2>
                            <p className="text-sm font-medium text-gray-100">
                                {conversations.length} messages
                            </p>
                        </div>
                    </div>
                    <div>
                        <Tab.Group selectedIndex={tab} onChange={setTab}>
                            <Tab.List className="w-full rounded-none">
                                {tabs.map((tab, idx) => (
                                    <Tab key={idx}>{tab.label}</Tab>
                                ))}
                            </Tab.List>
                        </Tab.Group>
                    </div>
                    <nav aria-label="Message list" className="min-h-0 flex-1 overflow-y-auto">
                        <ul
                            role="list"
                            className="divide-y divide-gray-700 border-b border-gray-700"
                        >
                            {conversationsQuery.isLoading
                                ? Array(7)
                                      .fill(0)
                                      .map((_, idx) => (
                                          <li
                                              key={`loading_${idx}`}
                                              className="py-4 px-5 xl:px-6 animate-pulse grid grid-cols-4 gap-x-4 gap-y-4"
                                          >
                                              <div className="h-2 bg-gray-600 rounded col-span-2" />
                                              <div className="h-2 bg-gray-700 rounded col-start-4 col-span-1" />
                                              <div className="h-2 bg-gray-600 rounded col-span-4" />
                                              <div className="h-2 bg-gray-700 rounded col-span-3" />
                                          </li>
                                      ))
                                : filteredConversations.map((conversation) => {
                                      const timestamp = DateTime.fromJSDate(
                                          conversation.lastMessage?.createdAt ??
                                              conversation.createdAt
                                      )
                                      const isToday =
                                          timestamp.toISODate() === DateTime.local().toISODate()

                                      return (
                                          <li key={conversation.id}>
                                              <Link
                                                  href={`/conversations/${conversation.id}`}
                                                  className={cn(
                                                      'block py-4 px-4 xl:px-5 focus-within:ring-2 focus-within:ring-inset focus-within:ring-cyan hover:bg-gray-700',
                                                      {
                                                          'bg-gray-700 ring-2 ring-inset ring-cyan':
                                                              router.asPath ===
                                                              `/conversations/${conversation.id}`,
                                                      }
                                                  )}
                                              >
                                                  <div
                                                      className={cn(
                                                          'space-y-1.5',
                                                          conversation.status === 'closed' &&
                                                              'opacity-60'
                                                      )}
                                                  >
                                                      {/* line 1 */}
                                                      <div className="flex items-center justify-between space-x-2">
                                                          <div className="min-w-0 flex-1">
                                                              <p className="truncate text-sm font-medium text-white">
                                                                  {conversation.title}
                                                              </p>
                                                          </div>
                                                          <time
                                                              dateTime={timestamp.toISO()}
                                                              className="shrink-0 whitespace-nowrap text-sm text-gray-100"
                                                          >
                                                              {isToday
                                                                  ? timestamp.toLocaleString(
                                                                        DateTime.TIME_SIMPLE
                                                                    )
                                                                  : timestamp.toLocaleString({
                                                                        ...DateTime.DATE_SHORT,
                                                                        year: '2-digit',
                                                                    })}
                                                          </time>
                                                      </div>

                                                      {/* line 2 */}
                                                      <div className="flex items-start justify-between space-x-2">
                                                          <div className="min-w-0 flex-1">
                                                              <ConversationPreview
                                                                  conversation={conversation}
                                                              />
                                                          </div>
                                                          <ConversationStatusIndicator
                                                              me={meQuery.data}
                                                              conversation={conversation}
                                                          />
                                                      </div>
                                                  </div>
                                              </Link>
                                          </li>
                                      )
                                  })}
                        </ul>
                        <div className="p-4 text-sm text-gray-200 text-center">
                            {filteredConversations.length} messages
                        </div>
                    </nav>
                </div>
            </aside>
        </div>
    )
}

export function ConversationPreview({ conversation }: { conversation: Conversation }) {
    const message = conversation.lastMessage
    const textPreview = useRichTextPreview(message?.body)

    return (
        <p className="text-sm text-gray-100 line-clamp-2">
            {textPreview || (message?.mediaSrc ? '<attachment>' : '<no messages>')}
        </p>
    )
}

export function ConversationStatusIndicator({
    me,
    conversation,
}: {
    me?: RouterOutput['users']['me']
    conversation: Conversation
}) {
    const status =
        conversation.status === 'closed'
            ? 'closed'
            : conversation.lastMessage
            ? 'in-progress'
            : 'new'

    if (status === 'closed')
        return (
            <span className="text-sm text-gray-100 flex items-center gap-1">
                Closed <RiCheckLine />
            </span>
        )

    if (conversation.lastMessage?.user?.advisor) {
        const isMe = conversation.lastMessage.userId === me?.id

        return (
            <div className="flex items-center space-x-1.5">
                {isMe && <RiReplyFill size={12} className="text-gray-100" />}
                <img
                    src={conversation.lastMessage.user.advisor.avatarSrc}
                    alt="advisor avatar"
                    className="h-5 w-5 rounded-full"
                />
            </div>
        )
    }

    return (
        <div
            className={cn(
                'relative h-4 w-4 rounded-full border-2',
                status === 'in-progress' ? 'border-yellow' : 'border-gray-25'
            )}
        >
            {status === 'in-progress' && (
                <div
                    className={cn(
                        'absolute right-0 inset-y-0 w-1/2 rounded-tr-full rounded-br-full bg-yellow'
                    )}
                />
            )}
        </div>
    )
}
