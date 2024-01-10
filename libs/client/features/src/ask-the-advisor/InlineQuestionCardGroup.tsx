import { useState } from 'react'
import type { IconType } from 'react-icons'
import { RiCloseFill } from 'react-icons/ri'
import AnimateHeight from 'react-animate-height'
import { NewConversationDialog } from './NewConversationDialog'
import { useLocalStorage, useUserApi } from '@maybe-finance/client/shared'
import { Button } from '@maybe-finance/design-system'
import type { Account, Plan } from '@prisma/client'
import Link from 'next/link'

type InlineQuestion = {
    icon: IconType
    title: string
    description?: string
}

type InlineQuestionCardGroupProps = {
    id: string
    questions: InlineQuestion[]
    heading?: string
    subheading?: string
    accountId?: Account['id']
    planId?: Plan['id']
    className?: string
}

export function InlineQuestionCardGroup({
    id,
    questions,
    heading,
    subheading,
    accountId,
    planId,
    className,
}: InlineQuestionCardGroupProps) {
    const { useSubscription } = useUserApi()
    const subscription = useSubscription()

    const [selectedQuestion, setSelectedQuestion] = useState<string | null>(null)

    return (
        <>
            <div className={className}>
                {(heading || subheading) && (
                    <div className="mb-4">
                        {heading && <h5 className="uppercase">{heading}</h5>}
                        {subheading && <p className="text-base text-gray-50">{subheading}</p>}
                    </div>
                )}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {questions.map(({ icon: Icon, title, description }, idx) => (
                        <div
                            key={idx}
                            className="flex space-x-4 p-4 rounded-lg bg-gray-800 text-gray-100 py-3 px-4 items-center"
                        >
                            <Icon className="shrink-0 w-6 h-6" />
                            <div className="grow shrink-1 text-base">
                                <span className="text-white">{title}</span>
                                {description && <p>{description}</p>}
                            </div>
                            <div className="shrink-0 flex flex-col items-end justify-between">
                                {!subscription.data?.subscribed ? (
                                    <Link href="/ask-the-advisor">
                                        <Button as="a" variant="secondary" className="!py-1 !px-3">
                                            Ask
                                        </Button>
                                    </Link>
                                ) : (
                                    <Button
                                        as="a"
                                        variant="secondary"
                                        className="!py-1 !px-3"
                                        onClick={() => setSelectedQuestion(title)}
                                    >
                                        Ask
                                    </Button>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            <NewConversationDialog
                open={!!selectedQuestion}
                onClose={() => setSelectedQuestion(null)}
                title={selectedQuestion ?? ''}
                accountId={accountId}
                planId={planId}
            />
        </>
    )
}
