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

export function IncomePayingDebt({ defaultState }: { defaultState: InsightState }): JSX.Element {
    const scrollContainer = useRef<HTMLDivElement>(null)

    const definition = useRef<HTMLDivElement>(null)
    const howAreWeGettingThisValue = useRef<HTMLDivElement>(null)
    const whyYouShouldCare = useRef<HTMLDivElement>(null)
    const incorrectData = useRef<HTMLDivElement>(null)

    const [performance, setPerformance] = useState<InsightState>(defaultState)

    return (
        <div className="flex flex-col w-full h-full">
            <h5 className="px-4 font-display font-bold text-2xl">Income paying debt</h5>
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
                    This is how much of your income is going towards paying debt. This is also
                    called the debt-to-income ratio. Ideally this is <Em>less than 36%</Em>.
                    <ExplainerInfoBlock title="TL;DR">
                        The % of money you make that pays debt
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
                            Monthly debt payments &divide; Monthly income
                        </span>
                    </ExplainerInfoBlock>
                </ExplainerSection>

                <ExplainerSection title="Why you should care" ref={whyYouShouldCare}>
                    The income paying debt is one of the ways lenders measure your ability to manage
                    monthly payments to repay money that you intend to borrow.
                    <ExplainerPerformanceBlock variant={InsightStateColors[performance]}>
                        <div className="flex items-center">
                            If your income paying debt is{' '}
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
                                    {['healthy', 'review', 'at-risk'].map((option) => (
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
                                        You may be spending too much of your income paying debts
                                    </li>
                                    <li>
                                        Postpone any large purchases that may use credit, to make
                                        sure you avoid taking on more debt
                                    </li>
                                    <li>
                                        If possible, increase the amount you pay monthly towards
                                        your debt to reduce your debt-to-income
                                    </li>
                                </>
                            )}
                            {performance === 'review' && (
                                <>
                                    <li>
                                        Postpone any large purchases that may use credit, to make
                                        sure you avoid taking on more debt
                                    </li>
                                    <li>
                                        If possible, increase the amount you pay monthly towards
                                        your debt to reduce your debt-to-income
                                    </li>
                                    <li>
                                        You could also see if you could reconfigure some parts of
                                        your loans, like extending duration or seeing if
                                        you&rsquo;re eligible for a lower interest rate
                                    </li>
                                </>
                            )}
                            {performance === 'healthy' && (
                                <>
                                    <li>Your income is paying for an appropriate amount of debt</li>
                                    <li>Lenders are likely to be willing to offer credit to you</li>
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
