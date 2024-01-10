import type { IconType } from 'react-icons'
import { type ReactElement, useRef } from 'react'
import { RiskSlider, WithOnboardingLayout } from '@maybe-finance/client/features'
import { useEffect, useState } from 'react'
import { Button, Checkbox, Step } from '@maybe-finance/design-system'
import {
    RiArrowDownSLine,
    RiArrowUpSLine,
    RiLineChartLine,
    RiMoneyDollarBoxLine,
    RiPencilLine,
    RiPushpinLine,
    RiScales3Line,
} from 'react-icons/ri'
import { GiPalmTree } from 'react-icons/gi'
import { FaCheck } from 'react-icons/fa'
import classNames from 'classnames'
import { useRouter } from 'next/router'
import { useUserApi } from '@maybe-finance/client/shared'
import toast from 'react-hot-toast'

import { useQueryClient } from '@tanstack/react-query'
import { ATAUtil, type SharedType } from '@maybe-finance/shared'
import { Controller, useForm } from 'react-hook-form'
import { Listbox, RadioGroup } from '@headlessui/react'

type Goal = {
    key: string
    text: string
    icon: IconType
}

const goalsList: Goal[] = [
    {
        key: 'retire',
        text: 'I would like to retire comfortably',
        icon: GiPalmTree,
    },
    {
        key: 'debt',
        text: 'I need to pay off debt',
        icon: RiScales3Line,
    },
    {
        key: 'save',
        text: 'I want to save up for something',
        icon: RiMoneyDollarBoxLine,
    },
    {
        key: 'invest',
        text: 'I need help investing',
        icon: RiLineChartLine,
    },
]

type FormFields = {
    goals: Goal[]
    customGoal: string
    userNotes: string
    riskAnswers: SharedType.RiskAnswer[]
}

const { riskQuestions, calcRiskProfile } = ATAUtil

export default function AskTheAdvisorPage() {
    const queryClient = useQueryClient()
    const router = useRouter()
    const { r: redirectTo } = router.query
    const questionsRef = useRef<Map<number, HTMLElement> | null>(null)
    const [currentStep, setCurrentStep] = useState(0)
    const [currentRiskQuestion, setCurrentRiskQuestion] = useState(0)
    const [accepted, setAccepted] = useState(false)

    const { useUpdateProfile, useProfile } = useUserApi()

    const updateProfile = useUpdateProfile({
        onError: () => {
            toast.error('Error updating user')
        },
        onSettled: () => {
            queryClient.invalidateQueries(['users'])
        },
        onSuccess: () => {
            router.push({ pathname: redirectTo?.toString() || '/ask-the-advisor' })
            toast.success('Saved profile!', { duration: 2_000 })
        },
    })

    const {
        handleSubmit,
        register,
        control,
        formState: { isValid },
        watch,
        reset,
    } = useForm<FormFields>({ defaultValues: { riskAnswers: [], goals: [] } })

    const profile = useProfile({
        onSuccess: (user) => {
            reset({
                goals: goalsList.filter((g) => user.goals.includes(g.key)),
                riskAnswers: user.riskAnswers,
                customGoal: user.goals.filter(
                    (g) => goalsList.find((gk) => gk.key === g) === undefined
                )?.[0],
                userNotes: user.userNotes ?? '',
            })
        },
        refetchOnMount: 'always',
        staleTime: Infinity,
    })

    const [goals, customGoal, riskAnswers] = watch(['goals', 'customGoal', 'riskAnswers'])
    const riskProfile = calcRiskProfile(riskQuestions, riskAnswers)
    const onboardingComplete = isValid && (customGoal || goals.length) && riskProfile

    const isFirstTimeEditing =
        profile.data && (!profile.data.goals.length || !profile.data.riskAnswers.length)

    function getQuestionsMap() {
        if (!questionsRef.current) questionsRef.current = new Map()
        return questionsRef.current
    }

    useEffect(() => {
        const handleKey = (key: KeyboardEvent) => {
            if (key.key === 'Enter') {
                setCurrentRiskQuestion((prev) =>
                    prev === riskQuestions.length - 1 ? riskQuestions.length - 1 : prev + 1
                )
            }

            if (key.key === '\\') {
                setCurrentRiskQuestion((prev) => (prev === 0 ? 0 : prev - 1))
            }
        }

        document.addEventListener('keydown', handleKey)

        // Ensure query re-fetches on mount (in case coming from route that already has profile query in cache)
        queryClient.invalidateQueries(['users'])

        return () => window.removeEventListener('keydown', handleKey)
    }, [queryClient])

    // Every time active question changes, make sure it is centered in view
    useEffect(() => {
        const map = getQuestionsMap()
        const node = map.get(currentRiskQuestion)
        node?.scrollIntoView({
            behavior: 'smooth',
            block: 'center',
        })
    }, [currentRiskQuestion])

    return (
        <form
            onSubmit={handleSubmit(({ userNotes, customGoal, goals, riskAnswers }) => {
                updateProfile.mutate({
                    userNotes,
                    riskAnswers,
                    goals: [...goals.map((g) => g.key), customGoal],
                })
            })}
        >
            <div className="flex flex-col items-center">
                <Step.Group currentStep={currentStep}>
                    <Step.List>
                        {isFirstTimeEditing && <Step>Consent</Step>}
                        <Step>Goals</Step>
                        <Step>Risk</Step>
                        <Step className="hidden">Review</Step>
                    </Step.List>
                    <Step.Panels className="my-4 text-white pt-4 lg:pt-20 pb-20">
                        {isFirstTimeEditing && (
                            <Step.Panel className="space-y-4 text-gray-50 text-base">
                                <h3 className="text-center text-white">
                                    Do you consent to advisor access to your account data?
                                </h3>

                                <p>
                                    To make sure advisors have the full picture around your
                                    financial situation, you&lsquo;ll need to grant us permission to
                                    let them view your accounts.
                                </p>

                                <div>
                                    <p className="font-medium text-white">
                                        {'->'} Why do the advisors need this?
                                    </p>
                                    <p>
                                        Besides giving you advice that&lsquo;s more personalized to
                                        your situation, you&lsquo;ll be enabling them to understand
                                        where you are with your finances in relation to where you
                                        want to be.
                                    </p>
                                </div>

                                <div>
                                    <p className="font-medium text-white">
                                        {'->'} What level of access are you granting here?
                                    </p>
                                    <p>
                                        This access means that they&lsquo;ll be able to read
                                        balances, account names, allocation as well as any plans
                                        you&lsquo;ve made on Maybe.
                                    </p>
                                </div>

                                <div>
                                    <p className="font-medium text-white">
                                        {'->'} Will advisors always be able to see my data?
                                    </p>
                                    <p>
                                        No. We only give advisors a snapshot of your financial
                                        account data when you request a service. If you don&lsquo;t
                                        ask advisors a question, they will not have access to your
                                        data.
                                    </p>
                                </div>

                                <p>
                                    Our advisors will never have access to your account credentials
                                    in any capacity.
                                </p>

                                <div className="bg-gray-600 p-4 space-y-4 rounded-lg">
                                    <div className="flex gap-2 items-start">
                                        <Checkbox
                                            checked={accepted}
                                            onChange={setAccepted}
                                            className="mt-1"
                                            dark
                                        />
                                        <p className="text-white">
                                            I have read all the text above and consent to sharing
                                            access to only my account data with my financial
                                            advisor.
                                        </p>
                                    </div>
                                    <Button
                                        disabled={!accepted}
                                        fullWidth
                                        onClick={() => setCurrentStep((prev) => prev + 1)}
                                    >
                                        Continue
                                    </Button>
                                </div>
                            </Step.Panel>
                        )}

                        <Step.Panel>
                            <h3 className="text-center text-white mb-2">
                                What goals should your advisor know about?
                            </h3>

                            <p className="text-center text-gray-100 text-base">
                                You can pick more than one goal and add more context below
                            </p>

                            <Controller
                                control={control}
                                name="goals"
                                render={({ field }) => (
                                    <Listbox multiple value={field.value} onChange={field.onChange}>
                                        <Listbox.Options
                                            className="space-y-3 mt-6 text-base"
                                            static
                                        >
                                            {goalsList.map((goal) => (
                                                <Listbox.Option key={goal.key} value={goal}>
                                                    {({ selected }) => (
                                                        <span
                                                            className={classNames(
                                                                'border cursor-pointer rounded-xl bg-gray-800 p-4 flex items-center gap-2 hover:bg-gray-700',
                                                                selected
                                                                    ? 'border-cyan bg-gray-700'
                                                                    : 'border-transparent'
                                                            )}
                                                        >
                                                            <goal.icon
                                                                size={18}
                                                                className={
                                                                    selected
                                                                        ? 'text-cyan'
                                                                        : 'text-gray-100'
                                                                }
                                                            />
                                                            {goal.text}
                                                            {selected && (
                                                                <div className="bg-cyan rounded-full w-4 h-4 flex justify-center items-center ml-auto">
                                                                    <FaCheck
                                                                        size={10}
                                                                        className="text-black"
                                                                    />
                                                                </div>
                                                            )}
                                                        </span>
                                                    )}
                                                </Listbox.Option>
                                            ))}
                                        </Listbox.Options>
                                    </Listbox>
                                )}
                            />

                            <div className="mt-6 text-base flex flex-col">
                                <p className="text-gray-100 text-base mb-1 mt-6">
                                    Have a custom goal?{' '}
                                    <span className="italic text-gray-50">Optional</span>
                                </p>

                                <textarea
                                    className="w-full custom-gray-scroll bg-gray-500 h-32 rounded resize-none focus:outline-none focus:ring-0 focus:border-0 text-base placeholder:text-gray-100"
                                    placeholder="e.g. I want to build up savings so I can have an emergency fund"
                                    {...register('customGoal')}
                                />
                            </div>

                            <div className="mt-6 flex justify-end space-x-3">
                                {isFirstTimeEditing && (
                                    <Button
                                        variant="secondary"
                                        onClick={() => setCurrentStep((prev) => prev - 1)}
                                    >
                                        Back
                                    </Button>
                                )}
                                <Button
                                    disabled={!customGoal && !goals.length}
                                    onClick={() => setCurrentStep((prev) => prev + 1)}
                                >
                                    Next
                                </Button>
                            </div>

                            <div className="bg-gradient-to-t from-transparent to-gray-800 flex gap-2 text-base mt-6 p-4 rounded-xl">
                                <RiPushpinLine size={16} className="shrink-0 text-gray-100 mt-1 " />
                                <div>
                                    <p className="font-medium">Why is this important?</p>
                                    <p className="text-gray-100">
                                        Letting your advisor know what&lsquo;s on your mind with
                                        regards to short-term and long-term goals, helps them give
                                        you personalized advice with the necessary amount of
                                        context.
                                    </p>
                                </div>
                            </div>
                        </Step.Panel>
                        <Step.Panel>
                            <h3 className="text-center text-white mb-2">
                                Let&lsquo;s see what your risk profile looks like
                            </h3>

                            <p className="text-center text-gray-100 text-base">
                                Fill in the details and answer a few questions to help us determine
                                your risk tolerance
                            </p>

                            <Controller
                                name="riskAnswers"
                                control={control}
                                render={({ field }) => (
                                    <>
                                        {riskQuestions.map((question, questionIdx) => {
                                            const currentAnswer = riskAnswers.find(
                                                (ra) => ra.questionKey === question.key
                                            )

                                            const currentChoice = question.choices.find(
                                                (c) => c.key === currentAnswer?.choiceKey
                                            )

                                            return (
                                                <div
                                                    key={questionIdx}
                                                    ref={(node) => {
                                                        const map = getQuestionsMap()
                                                        if (node) {
                                                            map.set(questionIdx, node)
                                                        } else {
                                                            map.delete(questionIdx)
                                                        }
                                                    }}
                                                >
                                                    <RiskQuestion
                                                        label={`Question ${questionIdx + 1}`}
                                                        isActive={
                                                            currentRiskQuestion === questionIdx
                                                        }
                                                        question={question}
                                                        choice={currentChoice}
                                                        onChoice={(choice) => {
                                                            const answersClone = structuredClone(
                                                                field.value
                                                            )

                                                            const prevAnswerIdx =
                                                                answersClone.findIndex(
                                                                    (a) =>
                                                                        a.questionKey ===
                                                                        question.key
                                                                )

                                                            const newAnswer = {
                                                                questionKey: question.key,
                                                                choiceKey: choice.key,
                                                            }

                                                            if (prevAnswerIdx >= 0) {
                                                                answersClone[prevAnswerIdx] =
                                                                    newAnswer
                                                            } else {
                                                                answersClone.push(newAnswer)
                                                            }

                                                            field.onChange(answersClone)
                                                        }}
                                                    />
                                                    {currentRiskQuestion === questionIdx && (
                                                        <QuestionNav
                                                            onNext={() =>
                                                                setCurrentRiskQuestion(
                                                                    (prev) => prev + 1
                                                                )
                                                            }
                                                            onPrev={() =>
                                                                setCurrentRiskQuestion(
                                                                    (prev) => prev - 1
                                                                )
                                                            }
                                                            hasNext={
                                                                currentRiskQuestion !==
                                                                riskQuestions.length - 1
                                                            }
                                                            hasPrev={currentRiskQuestion !== 0}
                                                        />
                                                    )}
                                                </div>
                                            )
                                        })}
                                    </>
                                )}
                            />

                            <div className="mt-6 self-end space-x-3">
                                <Button
                                    variant="secondary"
                                    onClick={() => setCurrentStep((prev) => prev - 1)}
                                >
                                    Back
                                </Button>
                                <Button
                                    disabled={riskAnswers.length < 5}
                                    onClick={() => setCurrentStep((prev) => prev + 1)}
                                >
                                    Next
                                </Button>
                            </div>
                        </Step.Panel>
                        <Step.Panel>
                            <h3 className="text-center text-white mb-2">
                                Here&lsquo;s what our advisors will know about you
                            </h3>

                            <p className="text-center text-gray-100 text-base">
                                If necessary, feel free to go back and edit any of the information
                                you&lsquo;ve provided so far.
                            </p>

                            <div className="bg-gray-800 px-4 py-5 rounded-xl mt-6 mb-4 text-base">
                                <div className="flex items-center justify-between mb-4">
                                    <h5 className="uppercase">Goals</h5>
                                    <Button
                                        className="h-8 pl-0 pr-2"
                                        variant="secondary"
                                        leftIcon={<RiPencilLine size={15} className="ml-2" />}
                                        onClick={() => setCurrentStep(0)}
                                    >
                                        Edit
                                    </Button>
                                </div>

                                <div className="space-y-2">
                                    {goals.map((goal) => {
                                        return (
                                            <div
                                                key={goal.key}
                                                className={classNames(
                                                    'rounded-xl bg-gray-600 p-4 flex items-center gap-2'
                                                )}
                                            >
                                                <goal.icon size={18} className="text-gray-100" />
                                                <span>{goal.text}</span>
                                            </div>
                                        )
                                    })}
                                    {customGoal && (
                                        <div className="rounded-xl bg-gray-600 p-4 space-y-2">
                                            <p className="text-gray-100 text-sm">Custom goal(s)</p>
                                            <p className="whitespace-pre-wrap">{customGoal}</p>
                                        </div>
                                    )}
                                </div>
                            </div>

                            <div className="bg-gray-800 px-4 py-5 rounded-xl mt-6 mb-4 text-base">
                                <div className="flex items-center justify-between mb-4">
                                    <h5 className="uppercase">Risk</h5>
                                    <Button
                                        className="h-8 pl-0 pr-2"
                                        variant="secondary"
                                        leftIcon={<RiPencilLine size={15} className="ml-2" />}
                                        onClick={() => setCurrentStep(1)}
                                    >
                                        Edit
                                    </Button>
                                </div>

                                <div className="text-gray-50">
                                    {riskProfile ? (
                                        <>
                                            <p>
                                                Based on your answers, we think your risk level is{' '}
                                                <span className="text-white">
                                                    {riskProfile.label}
                                                    {'. '}
                                                </span>
                                                <span>{riskProfile.description}</span>
                                            </p>

                                            <div className="h-20 mt-6">
                                                <RiskSlider score={riskProfile.score} />
                                            </div>
                                        </>
                                    ) : (
                                        <p>Incomplete risk profile</p>
                                    )}
                                </div>
                            </div>

                            <div className="mt-6 text-base flex flex-col">
                                <p className="text-gray-50 mb-1">
                                    Additional context{' '}
                                    <span className="italic text-gray-100">Optional</span>
                                </p>

                                <textarea
                                    className="custom-gray-scroll w-full bg-gray-500 h-32 rounded resize-none focus:outline-none focus:ring-0 focus:border-0 text-base placeholder:text-gray-100"
                                    placeholder="e.g I have a spouse and a couple of kids as dependents, so any advice I receive will need to take that into consideration."
                                    {...register('userNotes')}
                                />
                            </div>

                            <div className="mt-6 self-end space-x-3">
                                <Button
                                    variant="secondary"
                                    onClick={() => setCurrentStep((prev) => prev - 1)}
                                >
                                    Back
                                </Button>

                                <Button disabled={!onboardingComplete} type="submit">
                                    Finish
                                </Button>
                            </div>
                        </Step.Panel>
                    </Step.Panels>
                </Step.Group>
            </div>
        </form>
    )
}

AskTheAdvisorPage.getLayout = function getLayout(page: ReactElement) {
    return (
        <WithOnboardingLayout
            paths={[
                { title: 'Ask the advisor', href: '/ask-the-advisor' },
                { title: 'Questionnaire' },
            ]}
        >
            {page}
        </WithOnboardingLayout>
    )
}

type QuestionNavProps = {
    onNext(): void
    onPrev(): void
    hasNext: boolean
    hasPrev: boolean
}

function QuestionNav({ onNext, onPrev, hasNext, hasPrev }: QuestionNavProps) {
    return (
        <div className="flex items-center justify-between">
            <div className="flex items-center">
                {hasPrev && (
                    <>
                        <span className="text-white font-medium text-sm bg-gray-700 px-1 py-0.5 rounded">
                            \
                        </span>
                        <span className="text-sm text-gray-100 ml-2">Previous</span>
                    </>
                )}
                {hasNext && (
                    <>
                        <span className="text-white text-sm bg-gray-700 px-1 py-0.5 rounded ml-3">
                            Enter ⏎
                        </span>
                        <span className="text-sm text-gray-100 ml-2">Next</span>
                    </>
                )}
            </div>
            <div className="flex items-center gap-3 my-4">
                {hasPrev && (
                    <Button
                        variant="secondary"
                        leftIcon={<RiArrowUpSLine size={24} />}
                        onClick={onPrev}
                    />
                )}

                {hasNext && <Button leftIcon={<RiArrowDownSLine size={24} />} onClick={onNext} />}
            </div>
        </div>
    )
}

type RiskQuestionProps = {
    label: string
    question: SharedType.RiskQuestion
    isActive: boolean
    choice?: SharedType.RiskQuestionChoice
    onChoice(choice: SharedType.RiskQuestionChoice): void
}

function RiskQuestion({ label, question, isActive, choice, onChoice }: RiskQuestionProps) {
    return (
        <div className={classNames('p-4 rounded-xl mt-4 text-base', isActive && 'bg-gray-800')}>
            <span className="text-gray-100">{label}</span>
            <p className={classNames('my-2', isActive ? 'text-white' : 'text-gray-200')}>
                {question.text}
            </p>
            {isActive && (
                <RadioGroup value={choice} onChange={onChoice} className="space-y-2" as="ul">
                    {question.choices.map((choice) => (
                        <RadioGroup.Option
                            as="li"
                            key={choice.text}
                            value={choice}
                            className={({ checked }) =>
                                classNames(
                                    'border rounded-xl p-3 cursor-default text-base focus-visible:rounded-xl focus-visible:outline-cyan focus-visible:outline-none',
                                    checked ? 'border-cyan' : 'border-gray-600'
                                )
                            }
                        >
                            {({ checked }) => (
                                <div
                                    className={classNames(
                                        'flex items-center justify-between gap-2'
                                    )}
                                >
                                    <span className="text-white text-base">{choice.text}</span>

                                    {/* Circle centered inside a circle */}
                                    <span
                                        className={classNames(
                                            'relative inline-block w-4 h-4 rounded-full border shrink-0',
                                            checked ? 'border-cyan' : 'border-gray-300'
                                        )}
                                    >
                                        <span
                                            className={classNames(
                                                'absolute w-[10px] h-[10px] top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 rounded-full z-10',
                                                checked ? 'bg-cyan' : 'bg-transparent'
                                            )}
                                        />
                                    </span>
                                </div>
                            )}
                        </RadioGroup.Option>
                    ))}
                </RadioGroup>
            )}
        </div>
    )
}
