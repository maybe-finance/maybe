import type { SharedType } from '@maybe-finance/shared'
import { Attachment, RichText, type BoxIconVariant } from '@maybe-finance/client/shared'
import { AudioPlayer, VideoPlayer } from '@maybe-finance/client/shared'
import { BoxIcon, useLastUpdated } from '@maybe-finance/client/shared'
import {
    RiLockLine,
    RiNotificationBadgeLine,
    RiQuestionnaireLine,
    RiUserSearchLine,
} from 'react-icons/ri'
import { createContext, useContext, useMemo } from 'react'
import classNames from 'classnames'

export type ConversationProps = {
    conversation: SharedType.ConversationWithDetail
}

type ConversationContextType = {
    conversation: Omit<SharedType.ConversationWithDetail, 'advisors'>
    primaryAdvisor?: SharedType.AdvisorProfile
    secondaryAdvisors?: SharedType.AdvisorProfile[]
}

export const ConversationContext = createContext<ConversationContextType | undefined>(undefined)

export const useConversation = () => {
    const context = useContext(ConversationContext)
    if (context === undefined) {
        throw new Error('useConversation must be used within a ConversationProvider')
    }
    return context
}

function Message({
    message,
    isFirst,
    showBorder,
}: {
    message: SharedType.ConversationWithDetail['messages'][0]
    showBorder: boolean
    isFirst: boolean
}) {
    const lastUpdated = useLastUpdated(message.updatedAt, false)
    const advisor = message.user?.advisor

    const messageDetail = useMemo(() => {
        const variant = advisor ? 'indigo' : 'cyan'

        switch (message.type) {
            case 'text':
                return {
                    title: isFirst
                        ? 'Submitted question'
                        : advisor
                        ? `${advisor.fullName} left a message`
                        : 'You left a message',
                    icon: RiQuestionnaireLine,
                    variant,
                    body: (
                        <div
                            className={classNames('bg-gray-800 rounded-lg p-4 mt-4 mb-9 space-y-2')}
                        >
                            <RichText text={message.body} />
                            {message.mediaSrc && <Attachment href={message.mediaSrc} />}
                        </div>
                    ),
                }
            case 'video':
                return {
                    title: advisor
                        ? `${advisor.fullName} left a video message`
                        : 'You left a video message',
                    icon: RiNotificationBadgeLine,
                    variant,
                    body: (
                        <div className="mt-4 mb-9 space-y-4">
                            <RichText text={message.body} />
                            <VideoPlayer src={message.mediaSrc!} />
                        </div>
                    ),
                }
            case 'audio':
                return {
                    title: advisor
                        ? `${advisor.fullName} left an audio message`
                        : 'You left an audio message',
                    icon: RiNotificationBadgeLine,
                    variant,
                    body: (
                        <div className="mt-4 mb-9 space-y-4">
                            <RichText text={message.body} />
                            <AudioPlayer src={message.mediaSrc!} />
                        </div>
                    ),
                }
            default:
                throw new Error('Invalid message type: ' + message.type)
        }
    }, [message, advisor, isFirst])

    return (
        <div className="flex gap-4">
            {/* Icon and vertical line */}
            <div className="flex flex-col">
                {advisor ? (
                    <img
                        src={advisor.avatarSrc}
                        alt="advisor-avatar"
                        className="h-[36px] w-[36px] rounded-full"
                    />
                ) : (
                    <BoxIcon
                        icon={messageDetail.icon}
                        variant={messageDetail.variant as BoxIconVariant}
                        size="md"
                    />
                )}

                {showBorder && (
                    <div className="flex items-center justify-center my-4 grow">
                        <span className="bg-gray-500 h-full w-[2px]" />
                    </div>
                )}
            </div>

            <div className="max-w-[650px] w-full">
                <p className="text-base">
                    {messageDetail.title}
                    <span className="text-gray-100"> · {lastUpdated}</span>
                </p>

                {messageDetail.body}
            </div>
        </div>
    )
}

function Update({ update, showBorder }: { update: TimelineUpdate['update']; showBorder: boolean }) {
    const lastUpdated = useLastUpdated(update.timestamp, false)

    const updateDetails = useMemo(() => {
        switch (update.type) {
            case 'advisor-assigned':
                return {
                    icon: RiUserSearchLine,
                    variant: 'grape',
                    title: 'Advisor assigned, question in review',
                    message:
                        'An advisor has been assigned to this question.  You should receive an answer shortly.',
                }
            case 'conversation-closed':
                return {
                    icon: RiLockLine,
                    variant: 'red',
                    title: 'Conversation closed',
                    message: 'This conversation has been closed and locked for new responses.',
                }
            default:
                throw new Error('Invalid update type: ' + update.type)
        }
    }, [update.type])

    return (
        <div className="flex gap-4">
            {/* Icon and vertical line */}
            <div className="flex flex-col">
                <BoxIcon
                    icon={updateDetails.icon}
                    variant={updateDetails.variant as BoxIconVariant}
                    size="md"
                />

                {showBorder && (
                    <div className="flex items-center justify-center my-4 grow">
                        <span className="bg-gray-500 h-full w-[2px]" />
                    </div>
                )}
            </div>

            <div className="w-full max-w-[650px]">
                <p className="text-base">
                    {updateDetails.title}
                    <span className="text-gray-100"> · {lastUpdated}</span>
                </p>

                <p className="text-gray-100 text-base mt-4 mb-9">{updateDetails.message}</p>
            </div>
        </div>
    )
}

type TimelineUpdate = {
    type: 'update'
    update: {
        type: 'advisor-assigned' | 'conversation-closed'
        timestamp: Date
    }
}

type TimelineMessage = {
    type: 'message'
    message: SharedType.ConversationWithDetail['messages'][0]
}

type TimelineItem = TimelineMessage | TimelineUpdate

export function Conversation({ conversation }: ConversationProps) {
    const primaryAdvisor = conversation.advisors?.[0]?.advisor
    const secondaryAdvisors =
        conversation.advisors.length > 1
            ? conversation.advisors.slice(1).map((a) => a?.advisor)
            : []

    const timeline = useMemo<TimelineItem[]>(() => {
        const updates: TimelineUpdate[] = []

        if (conversation.status === 'closed') {
            updates.push({
                type: 'update',
                update: {
                    type: 'conversation-closed',
                    timestamp: conversation.updatedAt,
                },
            })
        }

        if (primaryAdvisor) {
            updates.push({
                type: 'update',
                update: {
                    type: 'advisor-assigned',
                    timestamp: conversation.advisors?.[0]?.createdAt,
                },
            })
        }

        const messages: TimelineMessage[] = conversation.messages.map((message) => ({
            type: 'message',
            message,
        }))

        // Merges messages and events in reverse chronological order
        return [...messages, ...updates].sort((a, b) => {
            const aTime = a.type === 'message' ? a.message.createdAt : a.update.timestamp
            const bTime = b.type === 'message' ? b.message.createdAt : b.update.timestamp

            return bTime.valueOf() - aTime.valueOf()
        })
    }, [conversation, primaryAdvisor])

    return (
        <ConversationContext.Provider value={{ primaryAdvisor, secondaryAdvisors, conversation }}>
            <div>
                {timeline.map((item, idx) =>
                    item.type === 'message' ? (
                        <Message
                            key={item.message.id}
                            message={item.message}
                            showBorder={idx !== timeline.length - 1}
                            isFirst={item.message.id === conversation.messages?.[0].id}
                        />
                    ) : (
                        <Update
                            key={item.update.type}
                            update={item.update}
                            showBorder={idx !== timeline.length - 1}
                        />
                    )
                )}
            </div>
        </ConversationContext.Provider>
    )
}
