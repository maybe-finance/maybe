import { IndexTabs, Listbox } from '@maybe-finance/design-system'
import Link from 'next/link'
import type { ReactNode } from 'react'
import { useState } from 'react'
import { useRef } from 'react'
import type { InsightState } from '../../'
import { InsightStateNames, InsightStateColors } from '../../'
import {
    ExplainerInfoBlock,
    ExplainerSection,
    ExplainerPerformanceBlock,
} from '@maybe-finance/client/shared'

const Em = ({ children }: { children: ReactNode }) => (
    <em className="not-italic text-gray-25">{children}</em>
)

export function SafetyNet({ defaultState }: { defaultState: InsightState }): JSX.Element {
    const scrollContainer = useRef<HTMLDivElement>(null)

    const definition = useRef<HTMLDivElement>(null)
    const howAreWeGettingThisValue = useRef<HTMLDivElement>(null)
    const whyYouShouldCare = useRef<HTMLDivElement>(null)
    const incorrectData = useRef<HTMLDivElement>(null)

    const [performance, setPerformance] = useState<InsightState>(defaultState)

    return (
        <div className="flex flex-col w-full h-full">
            <h5 className="px-4 font-display font-bold text-2xl">Safety net</h5>
            <div className="shrink-0 px-4 py-3">
                <IndexTabs
                    scrollContainer={scrollContainer}
                    sections={[
                        { name: 'Definition', elementRef: definition },
                        {
                            name: 'How are we getting this value?',
                            elementRef: howAreWeGettingThisValue,
                        },
                        {
                            name: 'Why you should care',
                            elementRef: whyYouShouldCare,
                        },
                        {
                            name: 'Incorrect data?',
                            elementRef: incorrectData,
                        },
                    ]}
                />
            </div>
            <div ref={scrollContainer} className="grow px-4 pb-16 basis-px custom-gray-scroll">
                <ExplainerSection title="Definition" ref={definition}>
                    Your safety net is the number of months <Em>you could pay expenses</Em> if you
                    were to only rely on your emergency funds.
                    <ExplainerInfoBlock title="TL;DR">
                        It&rsquo;s like your personal runway in case of emergency
                    </ExplainerInfoBlock>
                </ExplainerSection>

                <ExplainerSection
                    title="How are we getting this value?"
                    ref={howAreWeGettingThisValue}
                >
                    Is what you&rsquo;re probably asking when seeing that number. Well, below is the
                    formula we use:
                    <ExplainerInfoBlock title="Formula">
                        <span className="font-mono italic">
                            Cash or cash equivalent assets &divide; Monthly Expenses
                        </span>
                    </ExplainerInfoBlock>
                </ExplainerSection>

                <ExplainerSection title="Why you should care" ref={whyYouShouldCare}>
                    The safety net is a good measure of{' '}
                    <Em>
                        how much of a buffer you&rsquo;ve built, if something unexpected were to
                        happen
                    </Em>
                    , home repair, medical bills or anything of that nature.
                    <ExplainerPerformanceBlock variant={InsightStateColors[performance]}>
                        <div className="flex items-center">
                            If your safety net is{' '}
                            <Listbox
                                className="inline-block ml-2"
                                size="small"
                                value={performance}
                                onChange={setPerformance}
                            >
                                <Listbox.Button
                                    buttonClassName="!p-1.5 !h-auto !font-medium"
                                    variant={InsightStateColors[performance]}
                                >
                                    {InsightStateNames[performance]}
                                </Listbox.Button>
                                <Listbox.Options>
                                    {['excessive', 'healthy', 'review', 'at-risk'].map((option) => (
                                        <Listbox.Option key={option} value={option}>
                                            {InsightStateNames[option as InsightState]}
                                        </Listbox.Option>
                                    ))}
                                </Listbox.Options>
                            </Listbox>
                        </div>
                        <ul className="mt-2 list-disc list-outside ml-[1.5em]">
                            {performance === 'at-risk' && (
                                <>
                                    <li>
                                        You may not have enough cash to handle unexpected spending
                                        or emergencies
                                    </li>
                                    <li>
                                        You may want to review your savings and rate of spending
                                    </li>
                                </>
                            )}
                            {performance === 'review' && (
                                <>
                                    <li>You may have enough cash for some financial emergencies</li>
                                    <li>
                                        You should consider working to decrease spending or increase
                                        cash reserves
                                    </li>
                                </>
                            )}
                            {performance === 'healthy' && (
                                <>
                                    <li>
                                        You have enough cash to handle emergencies such as a
                                        temporary loss of income
                                    </li>
                                    <li>You can comfortably invest any excess income</li>
                                </>
                            )}
                            {performance === 'excessive' && (
                                <>
                                    <li>
                                        You may be running the risk of losing money to inflation if
                                        you hold onto too much cash
                                    </li>
                                    <li>
                                        If you&rsquo;re planning on deploying cash by timing the
                                        market, you should know this almost never works out in the
                                        long-term
                                    </li>
                                </>
                            )}
                        </ul>
                    </ExplainerPerformanceBlock>
                </ExplainerSection>

                <ExplainerSection title="Incorrect data?" ref={incorrectData}>
                    If you think the value we&rsquo;re showing you is incorrect, here&rsquo;s what
                    might be happening.
                    <ul className="list-disc list-outside ml-[1.5em]">
                        <li>
                            Our data provider misclassified a transaction/s, which you can{' '}
                            <Link href="/data-editor" className="text-cyan underline">
                                fix here
                            </Link>
                        </li>
                        <li>
                            We may not be getting enough data from the data provider around an
                            account(s)
                        </li>
                        <li>
                            You haven&rsquo;t connected all of your accounts, which is returning an
                            incorrect value, make sure to add all your accounts
                        </li>
                    </ul>
                </ExplainerSection>
            </div>
        </div>
    )
}
