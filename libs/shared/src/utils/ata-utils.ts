import type { ConversationNotification, RiskAnswer, RiskQuestion } from '../types'
import type { Conversation, Message, MessageType } from '@prisma/client'
import { DateTime } from 'luxon'
import { v4 as uuid } from 'uuid'
import sum from 'lodash/sum'
import { scaleQuantile } from '@visx/scale'

export function getEmailNotificationContent(type: ConversationNotification['type']) {
    switch (type) {
        case 'review':
            return {
                subject: 'An advisor has been assigned to your question',
                message:
                    'We have assigned an advisor to your question and they are gathering the information required to answer.  You should be receiving a response shortly.',
            }
        case 'update':
            return {
                subject: 'You have a new message from your advisor',
                message:
                    'A new message has been posted to your conversation.  Please go to your dashboard to view it.',
            }
        case 'closed':
            return {
                subject: 'Your conversation has been closed',
                message:
                    'Your conversation has been marked as closed and has been archived.  You can view all your past conversations in your dashboard.',
            }
        case 'expired':
            return {
                subject: 'Your conversation has expired',
                message:
                    'Your conversation has not received any new messages recently and has been closed due to inactivity.  If you still have unresolved questions feel free to open another one in your dashboard!',
            }
        default:
            throw new Error(`Invalid notification type provided type=${type}`)
    }
}

export function getUrls(conversationId: Conversation['id']) {
    return {
        conversation: `https://app.maybe.co/ask-the-advisor/${conversationId}`,
        settings: 'https://app.maybe.co/settings?tab=notifications',
    }
}

export function getExpiryStatus(
    conversation: Conversation & { messages: Pick<Message, 'createdAt'>[] }
) {
    const daysAgo = (d: Date) => {
        return Math.abs(DateTime.fromJSDate(d).diffNow('days').days)
    }

    const DAYS_UNTIL_EXPIRY_NOTIFICATION = 14
    const DAYS_UNTIL_EXPIRY = 17
    let refDate: Date | undefined

    if (!conversation.messages.length) {
        refDate = conversation.createdAt
    } else {
        refDate = conversation.messages.sort(
            (a, b) => b.createdAt.valueOf() - a.createdAt.valueOf()
        )[0].createdAt
    }

    if (daysAgo(refDate) >= DAYS_UNTIL_EXPIRY) {
        return 'expired'
    } else if (
        daysAgo(refDate) >= DAYS_UNTIL_EXPIRY_NOTIFICATION &&
        !conversation.expiryEmailSent
    ) {
        return 'expiring-soon'
    } else {
        return null
    }
}

// Based on common mime types - https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
export function mimeToMessageType(mime?: string): MessageType {
    if (!mime) return 'text'

    // Need to support multiple since user might upload their own audio/video files rather than recording
    const supportedAudioMimeTypes = [
        'audio/aac',
        'audio/wav',
        'audio/ogg',
        'audio/webm',
        'audio/mpeg', // .mp3
    ]
    const supportedVideoMimeTypes = [
        'video/mpeg',
        'video/mp4',
        'video/ogg',
        'video/webm',
        'video/quicktime', // .mov
        'video/x-msvideo', // .avi
    ]

    return supportedAudioMimeTypes.includes(mime)
        ? 'audio'
        : supportedVideoMimeTypes.includes(mime)
        ? 'video'
        : 'text' // anything not supported will show up as regular file upload
}

export function generateS3Filename(conversationId: Conversation['id']) {
    return `private/ask-my-advisor/cid${conversationId}-${uuid()}`
}

/**
 * Questions for AMA risk tolerance onboarding
 *
 * - OKAY to add/remove/re-order questions
 * - OKAY to re-order answers within a question
 * - NEVER change key values (they are used to dynamically construct the quiz)
 */
export const riskQuestions: RiskQuestion[] = [
    {
        key: '37cae883-ca70-4059-b185-85431c86b122',
        text: 'You are on a TV game show and can choose one of the following.  Which would you take?',
        choices: [
            {
                key: '604b03e4-b4de-40ba-ac53-3331e5d3ad76',
                text: '$1,000 in cash',
                riskScore: 1,
            },
            {
                key: '6dfed058-a76a-460a-a197-23242705028d',
                text: 'A 50% chance at winning $5,000',
                riskScore: 2,
            },
            {
                key: '80016d31-9c7b-444f-ba38-72f278f0b836',
                text: 'A 25% chance at winning $10,000',
                riskScore: 3,
            },
            {
                key: '67203867-b5a0-4a48-94e2-39e0dc6b05c2',
                text: 'A 5% chance at winning $100,000',
                riskScore: 4,
            },
        ],
    },
    {
        key: '369400eb-c571-406b-9182-15c52be7e934',
        text: 'You have just finished saving for a “once-in-a-lifetime” vacation.  Three weeks before you plan to leave, you lose your job.  You would:',
        choices: [
            {
                key: '01f14a87-b024-43fc-b00b-148779be8b97',
                text: 'Cancel the vacation',
                riskScore: 1,
            },
            {
                key: '86111b01-becf-4a1d-a0bc-892621feefd9',
                text: 'Take a much more modest vacation',
                riskScore: 2,
            },
            {
                key: '66fbb270-6adf-4ecc-928a-ae087281d27d',
                text: 'Go as scheduled, reasoning that you need the time to prepare for a job search',
                riskScore: 3,
            },
            {
                key: '5549b8a6-4f8b-4c5b-abc8-37a418ed9065',
                text: 'Extend your vacation, because this might be your last chance to go first-class',
                riskScore: 4,
            },
        ],
    },
    {
        key: '3d0ad4fc-a2ea-49e8-add6-4830023cb93c',
        text: 'When you think of the word “risk” which of the following words comes to mind first?',
        choices: [
            {
                key: '807af2cb-97c6-42ad-bdf4-d3557a4f1839',
                text: 'Loss',
                riskScore: 1,
            },
            {
                key: '28ece46e-c243-48cf-b8ca-8ef7583174d0',
                text: 'Uncertainty',
                riskScore: 2,
            },
            {
                key: '167a4ae3-63dd-48a6-be98-ad4307d049ee',
                text: 'Opportunity',
                riskScore: 3,
            },
            {
                key: '77142643-58e8-4d7c-84e7-d677602dc03c',
                text: 'Thrill',
                riskScore: 4,
            },
        ],
    },
    {
        key: '4124bcd7-9481-432e-ba4b-aa4534c902c8',
        text: 'Given the best and worst case returns of the four investment choices below, which would you prefer?',
        choices: [
            {
                key: '6ede11a4-683c-4234-a455-4828562c2a7b',
                text: '$200 gain best case; $0 gain/loss worst case',
                riskScore: 1,
            },
            {
                key: 'a0879e66-ad69-4c06-93cc-2c24cac44447',
                text: '$800 gain best case; $200 loss worst case',
                riskScore: 2,
            },
            {
                key: '591bb1e9-4b33-40fc-a660-11241b9a5ca7',
                text: '$2,600 gain best case; $800 loss worst case',
                riskScore: 3,
            },
            {
                key: 'e8180b64-ee56-42ae-9fb8-ef68b98df6d1',
                text: '$4,800 gain best case; $2,400 loss worst case',
                riskScore: 4,
            },
        ],
    },
    {
        key: '1498e650-03f0-4a69-aa19-85232e0d8dff',
        text: 'Suppose a relative left you an inheritance of $100,000, stipulating in the will that you invest ALL the money in ONE of the following choices.  Which one would you select?',
        choices: [
            {
                key: '81a4ad12-031b-4c25-9afe-7b220f46cdb0',
                text: 'A savings account or money market mutual fund',
                riskScore: 1,
            },
            {
                key: 'c02ffdc6-5e18-48a0-9d8e-b8c92a56e42c',
                text: 'A mutual fund that owns stocks and bonds',
                riskScore: 2,
            },
            {
                key: '72c15026-2a43-43f1-85f2-5d0e2d6108df',
                text: 'A portfolio of 15 common stocks',
                riskScore: 3,
            },
            {
                key: '7e0b2a5f-5b26-4781-a50d-ecf878e21e59',
                text: 'Commodities like gold, silver, and oil',
                riskScore: 4,
            },
        ],
    },
]

export function calcRiskProfile(questions: RiskQuestion[], answers: RiskAnswer[]) {
    function getRiskDescription(qualitativeScore: string) {
        switch (qualitativeScore) {
            case 'Low':
                return 'What this means is you want some predictability in your portfolio, and would prefer to balance out some of the risk with stability.'
            case 'Moderate':
                return 'This means that you prefer investments that offer a modest rate of return with very little downside risk.'
            case 'High':
                return 'This just means that you are okay dealing with volatility and are likely trying to earn an aggressive rate of return over your peers.'
            default:
                throw new Error(
                    'Invalid qualitative score provided, must be Low, Moderate, or High'
                )
        }
    }

    const withAnswers = questions.map((q) => {
        const answer = answers.find((a) => a.questionKey === q.key)
        return {
            ...q,
            answer: q.choices.find((c) => c.key === answer?.choiceKey),
        }
    })

    const riskScores = withAnswers
        .map((wa) => wa.answer?.riskScore)
        .filter((s): s is number => s != null)

    if (!riskScores.length) return null

    const avgRiskScore = sum(riskScores) / riskScores.length

    const qualitativeScore = scaleQuantile({
        domain: [1, 2, 3, 4],
        range: ['Low', 'Moderate', 'High'],
    })(avgRiskScore)

    return {
        score: avgRiskScore,
        label: qualitativeScore,
        description: getRiskDescription(qualitativeScore),
    }
}
