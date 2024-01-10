import type { Advisor, Conversation, ConversationAdvisor, Message } from '@prisma/client'

export type AdvisorProfile = Pick<Advisor, 'fullName' | 'title' | 'bio' | 'avatarSrc'>

export type ConversationWithDetail = Conversation & {
    advisors: (ConversationAdvisor & {
        advisor: AdvisorProfile
    })[]
    messages: (Message & {
        user: {
            advisor: AdvisorProfile | null
        } | null
    })[]
}

export type ConversationWithMessageSummary = Conversation & {
    advisors: (ConversationAdvisor & {
        advisor: AdvisorProfile
    })[]
    messageCount: number
    firstMessage: Message | null
    lastMessage: Message | null
}

export type ConversationNotification = {
    type: 'submitted' | 'review' | 'update' | 'closed' | 'expired'
    conversationId: Conversation['id']
}
