import { IndexTabs } from '@maybe-finance/design-system'
import classNames from 'classnames'
import Link from 'next/link'
import type { ReactNode } from 'react'
import { useRef } from 'react'
import { RiArrowRightDownLine, RiArrowRightUpLine } from 'react-icons/ri'
import {
    ExplainerInfoBlock,
    ExplainerSection,
    ExplainerPerformanceBlock,
} from '@maybe-finance/client/shared'

const Em = ({ children }: { children: ReactNode }) => (
    <em className="not-italic text-gray-25">{children}</em>
)

export function NetWorthTrend(): JSX.Element {
    const scrollContainer = useRef<HTMLDivElement>(null)

    const definition = useRef<HTMLDivElement>(null)
    const howAreWeGettingThisValue = useRef<HTMLDivElement>(null)
    const whyYouShouldCare = useRef<HTMLDivElement>(null)
    const incorrectData = useRef<HTMLDivElement>(null)

    return (
        <div className="flex flex-col w-full h-full">
            <h5 className="px-4 font-display font-bold text-2xl">Net worth trend</h5>
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
                        // {
                        //     name: 'Learn more',
                        //     elementRef: learnMore,
                        // },
                    ]}
                />
            </div>
            <div ref={scrollContainer} className="grow px-4 pb-16 basis-px custom-gray-scroll">
                <ExplainerSection title="Definition" ref={definition}>
                    This is an indicator of how your net worth is changing over time. Ideally the{' '}
                    trend is <Em>positive over a long period of time</Em> as you pay down debt and
                    acquire assets.
                    <ExplainerInfoBlock title="TL;DR">
                        It&rsquo;s your &ldquo;how am I doing money-wise?&rdquo;
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
                            [Latest net worth - Earliest net worth] &divide; Earliest net worth
                        </span>
                    </ExplainerInfoBlock>
                </ExplainerSection>

                <ExplainerSection title="Why you should care" ref={whyYouShouldCare}>
                    The net worth trend value helps to <Em>review where you are financially</Em>. It
                    lets you know <Em>what</Em> progress you&rsquo;re making and what moves you
                    should make.
                    <ExplainerPerformanceBlock variant="teal">
                        {(color) => (
                            <>
                                <div className="flex items-center">
                                    <RiArrowRightUpLine
                                        className={classNames('w-6 h-6 mr-2', color)}
                                    />
                                    <span>
                                        If you're trending <span className={color}>positively</span>
                                    </span>
                                </div>
                                <ul className="mt-2 list-disc list-outside ml-[1.5em]">
                                    <li>
                                        You&rsquo;re getting closer to your short and long-term
                                        goals
                                    </li>
                                    <li>
                                        Your actions are paying off, whether that&rsquo;s increasing
                                        you&rsquo;re income, having a good savings rate, or
                                        investing wisely
                                    </li>
                                </ul>
                            </>
                        )}
                    </ExplainerPerformanceBlock>
                    <ExplainerPerformanceBlock variant="red">
                        {(color) => (
                            <>
                                <div className="flex items-center">
                                    <RiArrowRightDownLine
                                        className={classNames('w-6 h-6 mr-2', color)}
                                    />
                                    <span>
                                        If you're trending <span className={color}>negatively</span>
                                    </span>
                                </div>
                                <ul className="mt-2 list-disc list-outside ml-[1.5em]">
                                    <li>
                                        Don&rsquo;t panic, this just means there&rsquo;s more room
                                        for improvement
                                    </li>
                                    <li>
                                        Understand your expenses and cut any unnecessary spending
                                    </li>
                                    <li>Build a plan for paying down any bad debt</li>
                                    <li>
                                        Take a more aggressive stance on saving your money and
                                        investing
                                    </li>
                                </ul>
                            </>
                        )}
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
