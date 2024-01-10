import { IndexTabs } from '@maybe-finance/design-system'
import { useRef } from 'react'
import { RiArticleLine } from 'react-icons/ri'

import {
    ExplainerExternalLink,
    ExplainerInfoBlock,
    ExplainerSection,
    ExplainerPerformanceBlock,
} from '@maybe-finance/client/shared'

export function AverageReturn(): JSX.Element {
    const scrollContainer = useRef<HTMLDivElement>(null)

    const definition = useRef<HTMLDivElement>(null)
    const howAreWeGettingThisValue = useRef<HTMLDivElement>(null)
    const learnMore = useRef<HTMLDivElement>(null)

    return (
        <div className="flex flex-col w-full h-full">
            <h5 className="px-4 font-display font-bold text-2xl">Average return</h5>
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
                            name: 'Learn more',
                            elementRef: learnMore,
                        },
                    ]}
                />
            </div>
            <div ref={scrollContainer} className="grow px-4 pb-16 basis-px custom-gray-scroll">
                <ExplainerSection title="Definition" ref={definition}>
                    This is the portfolio&rsquo;s return on investment. Basically, it&rsquo;s the
                    money made or lost on an investment over some period of time. It&rsquo;s also
                    the figure most investors refer to, to understand performance when compared to
                    benchmarks like the S&amp;P 500.
                    <ExplainerInfoBlock title="TL;DR">
                        It&rsquo;s your &ldquo;how much have I made?&rdquo; number
                    </ExplainerInfoBlock>
                </ExplainerSection>

                <ExplainerSection
                    title="How are we getting this value?"
                    ref={howAreWeGettingThisValue}
                >
                    Is what you&rsquo;re probably asking when seeing that number. We use the{' '}
                    <a
                        rel="noreferrer"
                        target="_blank"
                        href="https://www.investopedia.com/terms/m/modifieddietzmethod.asp"
                        className="text-cyan underline"
                    >
                        Modified Dietz Return
                    </a>{' '}
                    method to calculate this from your holding and transaction data.
                </ExplainerSection>

                <ExplainerSection title="Learn more" ref={learnMore}>
                    <ExplainerExternalLink
                        icon={RiArticleLine}
                        href="https://maybe.co/articles/equities-as-an-asset-class"
                    >
                        Article from the Maybe blog on making equity investing part of your
                        portfolio
                    </ExplainerExternalLink>
                </ExplainerSection>
            </div>
        </div>
    )
}
