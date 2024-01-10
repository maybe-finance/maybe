import { useState, useMemo, type ReactElement } from 'react'
import { useRouter } from 'next/router'
import Link from 'next/link'
import upperFirst from 'lodash/upperFirst'
import cn from 'classnames'
import {
    RiCheckboxMultipleLine,
    RiEqualizerLine,
    RiQuestionAnswerLine,
    RiTimeLine,
} from 'react-icons/ri'
import {
    MainContentOverlay,
    useConversationApi,
    useQueryParam,
    useUserApi,
} from '@maybe-finance/client/shared'
import {
    QuestionCardForm,
    QuestionCard,
    WithSidebarLayout,
    AccountSidebar,
    ConversationCard,
    DevOnlyMenu,
    type QuestionCategory,
    NewConversationDialog,
    OnboardingOverlay,
} from '@maybe-finance/client/features'
import { Button, Listbox, Tab } from '@maybe-finance/design-system'

type PresetQuestion = {
    title: string
    subtitle: string
    category: QuestionCategory
}

const faq: PresetQuestion[] = [
    {
        title: 'What can I do to minimize taxes annually?',
        subtitle: 'Find out if the advisor can help minimize tax spend with your current finances.',
        category: 'tax',
    },
    {
        title: 'Is my current investing strategy on track?',
        subtitle:
            'Check if your allocation and strategy are viable in relation to your goals and risk tolerance.',
        category: 'portfolio',
    },
    {
        title: 'How can I financially prepare for any emergencies?',
        subtitle:
            'Get peace of mind and financial preparedness if something unexpected like a global pandemic were to happen.',
        category: 'budgeting',
    },
    {
        title: 'What are some steps I can take to become debt free?',
        subtitle:
            'Get a handle on your debt by working with an advisor on a recovery plan and schedule for repayment.',
        category: 'debt',
    },
]

const reviews: PresetQuestion[] = [
    {
        title: 'Does my current asset allocation help or hinder my goals?',
        subtitle:
            'Figure out whether your choices so far when investing are helping your long-term goals',
        category: 'portfolio',
    },
    {
        title: 'Can you review my retirement plan?',
        subtitle:
            'Work with your advisor to review your retirement plan and see what works, what does not, and what needs changing',
        category: 'retirement',
    },
    {
        title: 'Can you take a look at my investment portfolio?',
        subtitle:
            'Get feedback on your portfolio so far and tips on whether there are assets with less risk that can provide you with a better return',
        category: 'portfolio',
    },
    {
        title: 'What does my current risk profile look like?',
        subtitle:
            'Find out if the risk you are currently taking is inline with your tolerance, or is under or over your expectations',
        category: 'risk',
    },
]

const future: PresetQuestion[] = [
    {
        title: 'How much should I be setting aside for retirement?',
        subtitle:
            '401ks.  IRAs.  Our advisors will help you make sense of it and design a plan for future you.',
        category: 'saving',
    },
    {
        title: 'How do I leave my assets to my loved ones?',
        subtitle:
            'Work with your advisor to find out how you can make an estate plan that takes care of your family',
        category: 'estate',
    },
    {
        title: "How can I save money for my child's college fund?",
        subtitle:
            "Build a savings plan with your advisor to save for children's college tuition expenses",
        category: 'saving',
    },
]

function SectionTitle({ title, count }: { title: string; count: number }) {
    return (
        <div className="flex items-center gap-2 mt-8 mb-4">
            <h5 className="uppercase">{title}</h5>
            <span className="bg-gray-700 py-0.5 px-1.5 rounded-md text-sm font-medium">
                {count}
            </span>
        </div>
    )
}

export default function AskTheAdvisorPage() {
    const router = useRouter()

    const [selectedQuestion, setSelectedQuestion] = useState<string>()
    const showDialog = !!selectedQuestion

    const { useProfile } = useUserApi()
    const { useConversations } = useConversationApi()

    const userProfile = useProfile()
    const query = useConversations()

    const conversations = useMemo(() => {
        if (!query.data) return null

        return {
            active: query.data.filter((c) => c.status === 'open'),
            closed: query.data.filter((c) => c.status === 'closed'),
        }
    }, [query.data])

    const tabs = useMemo(
        () => [
            {
                id: 'all',
                title: 'All questions',
                icon: RiQuestionAnswerLine,
            },
            {
                id: 'in-progress',
                title: 'In progress',
                icon: RiTimeLine,
                count: conversations?.active.length,
            },
            {
                id: 'completed',
                title: 'Completed',
                icon: RiCheckboxMultipleLine,
                count: conversations?.closed.length,
            },
        ],
        [conversations]
    )

    const currentTabId = useQueryParam('tab', 'string') || 'all'
    const currentTab = tabs.find((tab) => tab.id === currentTabId)

    if (query.isError || userProfile.isError) {
        return (
            <MainContentOverlay
                title="Unable to load conversations"
                actionText="Try again"
                onAction={() => window.location.reload()}
            >
                <p>Contact us if this issue persists.</p>
            </MainContentOverlay>
        )
    }

    return (
        <>
            <OnboardingOverlay />

            <NewConversationDialog
                open={showDialog}
                onClose={() => setSelectedQuestion(undefined)}
                title={selectedQuestion}
            />

            <section className="space-y-4">
                {process.env.NODE_ENV === 'development' && <DevOnlyMenu />}

                <div className="flex flex-wrap items-baseline justify-between">
                    <h3 className="max-w-[550px]">
                        {currentTabId === 'all'
                            ? `What can we help you with today, ${upperFirst(
                                  userProfile.data?.firstName ?? undefined
                              )}?`
                            : currentTabId === 'in-progress'
                            ? "Here's the questions you've been asking"
                            : "Here's all the questions that were answered"}
                    </h3>
                    <Link href="/ask-the-advisor/questionnaire" passHref className="mt-3 md:mt-0">
                        <Button
                            as="a"
                            variant="secondary"
                            leftIcon={<RiEqualizerLine size={18} className="text-gray-50" />}
                        >
                            Edit goals & risk
                        </Button>
                    </Link>
                </div>

                <Tab.Group
                    onChange={(idx) => {
                        router.replace({ query: { tab: tabs[idx].id } })
                    }}
                    selectedIndex={tabs.findIndex((tab) => tab.id === currentTabId)}
                >
                    <Tab.List className="bg-transparent hidden sm:inline-flex">
                        {tabs.map((tab) => (
                            <Tab
                                key={tab.title}
                                className="flex items-center gap-1 whitespace-nowrap"
                            >
                                {<tab.icon size={16} />}
                                {tab.title}
                                {tab.count != null && (
                                    <span
                                        className={cn(
                                            'ml-1 rounded-md w-5 h-5 inline-flex justify-center items-center text-sm',
                                            tab.id === currentTabId
                                                ? 'bg-gray-200 text-white'
                                                : 'bg-gray-500 text-gray-100'
                                        )}
                                    >
                                        {tab.count}
                                    </span>
                                )}
                            </Tab>
                        ))}
                    </Tab.List>

                    <Listbox
                        onChange={(idx: number) => {
                            router.replace({ query: { tab: tabs[idx].id } })
                        }}
                        value={tabs.findIndex((tab) => tab.id === currentTabId)}
                        className="sm:hidden"
                    >
                        <Listbox.Button>{currentTab?.title}</Listbox.Button>

                        <Listbox.Options>
                            {tabs.map((tab, idx) => (
                                <Listbox.Option key={tab.title} value={idx}>
                                    {tab.title}
                                </Listbox.Option>
                            ))}
                        </Listbox.Options>
                    </Listbox>

                    <Tab.Panels>
                        <Tab.Panel>
                            <SectionTitle title="Frequently asked" count={faq.length + 1} />

                            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                                {faq.map((question) => (
                                    <QuestionCard
                                        key={question.title}
                                        title={question.title}
                                        subtitle={question.subtitle}
                                        category={question.category}
                                        onClick={() => setSelectedQuestion(question.title)}
                                    />
                                ))}

                                <QuestionCardForm
                                    onSubmit={(data) => setSelectedQuestion(data.question)}
                                />
                            </div>

                            <SectionTitle title="Reviews" count={reviews.length} />

                            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                                {reviews.map((question) => (
                                    <QuestionCard
                                        key={question.title}
                                        title={question.title}
                                        subtitle={question.subtitle}
                                        category={question.category}
                                        onClick={() => setSelectedQuestion(question.title)}
                                    />
                                ))}
                            </div>

                            <SectionTitle title="Planning ahead" count={future.length} />

                            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                                {future.map((question) => (
                                    <QuestionCard
                                        key={question.title}
                                        title={question.title}
                                        subtitle={question.subtitle}
                                        category={question.category}
                                        onClick={() => setSelectedQuestion(question.title)}
                                    />
                                ))}
                            </div>
                        </Tab.Panel>
                        <Tab.Panel>
                            <div className="mt-8 space-y-8">
                                {conversations?.active.length ? (
                                    conversations.active.map((conversation) => (
                                        <ConversationCard
                                            key={conversation.id}
                                            conversation={conversation}
                                        />
                                    ))
                                ) : (
                                    <p className="text-gray-50 ml-4">
                                        You have no active conversations
                                    </p>
                                )}
                            </div>
                        </Tab.Panel>
                        <Tab.Panel>
                            <div className="mt-8 space-y-8">
                                {conversations?.closed.length ? (
                                    conversations.closed.map((conversation) => (
                                        <ConversationCard
                                            key={conversation.id}
                                            conversation={conversation}
                                        />
                                    ))
                                ) : (
                                    <p className="text-gray-50 ml-4">
                                        You have no completed conversations
                                    </p>
                                )}
                            </div>
                        </Tab.Panel>
                    </Tab.Panels>
                </Tab.Group>
            </section>
        </>
    )
}

AskTheAdvisorPage.getLayout = function getLayout(page: ReactElement) {
    return <WithSidebarLayout sidebar={<AccountSidebar />}>{page}</WithSidebarLayout>
}
