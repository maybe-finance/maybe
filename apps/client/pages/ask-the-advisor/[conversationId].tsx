import type { ReactElement } from 'react'
import {
    AdvisorCard,
    Conversation,
    NoAdvisorCardDesktop,
    OnboardingOverlay,
} from '@maybe-finance/client/features'
import {
    MainContentOverlay,
    MessageInput,
    useConversationApi,
    useQueryParam,
} from '@maybe-finance/client/shared'
import { Button, LoadingSpinner } from '@maybe-finance/design-system'
import { WithSidebarLayout, AccountSidebar } from '@maybe-finance/client/features'
import { RiArrowLeftSLine, RiCheckLine } from 'react-icons/ri'
import { DateTime } from 'luxon'
import Link from 'next/link'

export default function ATAConversationPage() {
    const conversationId = useQueryParam('conversationId', 'number')!

    // For now, keep advisors online during business hours until we implement a live status indicator
    const status = DateTime.now().hour >= 8 && DateTime.now().hour <= 16 ? 'online' : 'offline'

    const { useConversation, useUpdateConversation, useCreateMessage } = useConversationApi()
    const query = useConversation(conversationId, { enabled: !!conversationId })
    const update = useUpdateConversation()
    const send = useCreateMessage()

    const assignedAdvisor = query.data?.advisors?.[0]?.advisor

    if (query.isError) {
        return (
            <MainContentOverlay
                title="Unable to load conversation"
                actionText="Try again"
                onAction={() => window.location.reload()}
            >
                <p>Contact us if this issue persists.</p>
            </MainContentOverlay>
        )
    }

    if (query.isLoading) {
        return (
            <div className="absolute inset-0 flex items-center justify-center">
                <LoadingSpinner />
            </div>
        )
    }

    if (!query.data) return null

    return (
        <>
            <OnboardingOverlay />
            <div>
                <div className="flex items-center justify-between gap-4">
                    <Link
                        href={{
                            pathname: '/ask-the-advisor',
                            query: {
                                tab: query.data?.status === 'closed' ? 'completed' : 'in-progress',
                            },
                        }}
                        legacyBehavior
                    >
                        <Button
                            as="a"
                            variant="secondary"
                            leftIcon={<RiArrowLeftSLine size={20} className="shrink-0" />}
                        >
                            Back
                        </Button>
                    </Link>
                    <Button
                        variant="secondary"
                        disabled={query.data?.status === 'closed'}
                        leftIcon={<RiCheckLine size={20} className="shrink-0" />}
                        onClick={() => {
                            update.mutate({
                                id: conversationId,
                                data: {
                                    status: 'closed',
                                },
                            })
                        }}
                    >
                        {query.data?.status === 'closed'
                            ? 'Conversation resolved'
                            : 'Mark as complete'}
                    </Button>
                </div>

                <p className="text-base text-gray-100 pt-6">Question</p>

                <h3 className="max-w-[600px] mt-2">{query.data.title}</h3>

                <div className="flex flex-col sm:flex-row gap-6 pt-6">
                    <div className="w-full">
                        <div className="xl:hidden mb-4">
                            {assignedAdvisor ? (
                                <AdvisorCard
                                    mode="wide-standalone"
                                    advisor={assignedAdvisor}
                                    status={status}
                                />
                            ) : (
                                <NoAdvisorCardDesktop mode="wide-standalone" />
                            )}
                        </div>

                        <MessageInput
                            disabled={query.data.status === 'closed'}
                            placeholder={
                                query.data.status === 'open'
                                    ? 'Leave a message to your advisor...'
                                    : 'This conversation has been closed. Please raise a new question.'
                            }
                            onSubmit={(data) =>
                                send.mutateAsync({
                                    id: query.data.id,
                                    data,
                                })
                            }
                        />

                        <div className="pt-8">
                            <h5 className="uppercase mb-4">Updates</h5>

                            <Conversation conversation={query.data} />
                        </div>
                    </div>
                    <div className="hidden xl:block">
                        {assignedAdvisor ? (
                            <AdvisorCard advisor={assignedAdvisor} status={status} />
                        ) : (
                            <NoAdvisorCardDesktop />
                        )}
                    </div>
                </div>
            </div>
        </>
    )
}

ATAConversationPage.getLayout = function getLayout(page: ReactElement) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{page}</WithSidebarLayout>
}
