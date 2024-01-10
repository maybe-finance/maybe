import type { SharedType } from '@maybe-finance/shared'
import { useRichTextPreview } from '@maybe-finance/client/shared'
import { DateTime } from 'luxon'
import { useRouter } from 'next/router'
import { RiCheckboxMultipleLine, RiFileSearchLine, RiUserSearchLine } from 'react-icons/ri'
import { AdvisorCard } from './AdvisorCard'
import { ConversationMenu } from './ConversationMenu'
import { QuestionTag } from './QuestionTag'

type ConversationCardProps = {
    conversation: SharedType.ConversationWithMessageSummary
}

export function ConversationCard({ conversation }: ConversationCardProps) {
    const messagePreview = useRichTextPreview(
        conversation.lastMessage?.userId === conversation.userId
            ? conversation.lastMessage.body
            : null
    )

    // For now, keep advisors online during business hours until we implement a live status indicator
    const status = DateTime.now().hour >= 8 && DateTime.now().hour <= 16 ? 'online' : 'offline'
    const assignedAdvisor = conversation.advisors?.[0]?.advisor

    const router = useRouter()

    return (
        <div
            className="flex flex-col p-4 bg-gray-800 rounded-lg w-[600px] space-y-4 border border-transparent hover:border-cyan cursor-pointer"
            onClick={() => router.push(`/ask-the-advisor/${conversation.id}`)}
        >
            <div className="flex items-center justify-between gap-4">
                {conversation.status === 'closed' ? (
                    <QuestionTag
                        text="Resolved"
                        icon={RiCheckboxMultipleLine}
                        iconClassName="text-teal"
                    />
                ) : conversation.advisors.length > 0 ? (
                    <QuestionTag
                        text={'Currently in review'}
                        icon={RiFileSearchLine}
                        iconClassName="text-pink"
                    />
                ) : (
                    <QuestionTag
                        text={'Finding an advisor'}
                        icon={RiUserSearchLine}
                        iconClassName="text-cyan"
                    />
                )}

                {conversation.status !== 'closed' && (
                    <div onClick={(e) => e.stopPropagation()}>
                        <ConversationMenu conversationId={conversation.id} />
                    </div>
                )}
            </div>
            <div className="space-y-2">
                <h5>{conversation.title}</h5>
                {messagePreview && (
                    <p className="text-base text-gray-50 line-clamp-2">{messagePreview}</p>
                )}
            </div>
            {assignedAdvisor ? (
                <AdvisorCard advisor={assignedAdvisor} status={status} mode="wide" />
            ) : (
                <div className="bg-gray-700 p-3 rounded-lg text-gray-100">
                    <p className="text-base">
                        You will see your advisor here when we match them to your question ...
                    </p>
                </div>
            )}
        </div>
    )
}
