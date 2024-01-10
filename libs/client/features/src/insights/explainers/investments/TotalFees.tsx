import { IndexTabs } from '@maybe-finance/design-system'
import { useRef } from 'react'
import { RiArticleLine } from 'react-icons/ri'
import {
    ExplainerExternalLink,
    ExplainerInfoBlock,
    ExplainerSection,
} from '@maybe-finance/client/shared'

export function TotalFees(): JSX.Element {
    const scrollContainer = useRef<HTMLDivElement>(null)

    const definition = useRef<HTMLDivElement>(null)
    const howAreWeGettingThisValue = useRef<HTMLDivElement>(null)
    const learnMore = useRef<HTMLDivElement>(null)

    return (
        <div className="flex flex-col w-full h-full">
            <h5 className="px-4 font-display font-bold text-2xl">Total fees</h5>
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
                    These are the sum total of fees that you pay your broker for transacting on
                    their platform. Some examples of fees could be deposit, withdrawal, processing,
                    or advisory fees and even commissions on orders.
                    <ExplainerInfoBlock title="TL;DR">
                        What your broker charges you for using their platform
                    </ExplainerInfoBlock>
                </ExplainerSection>

                <ExplainerSection
                    title="How are we getting this value?"
                    ref={howAreWeGettingThisValue}
                >
                    Is what you&rsquo;re probably asking when seeing that number. Well, below is the
                    formula we use:
                    <ExplainerInfoBlock title="Formula">
                        <span className="font-mono italic">Total fees paid to brokerage</span>
                    </ExplainerInfoBlock>
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
