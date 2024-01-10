import { IndexTabs } from '@maybe-finance/design-system'
import type { ReactNode } from 'react'
import { useRef } from 'react'
import { RiArticleLine, RiMicLine } from 'react-icons/ri'
import {
    ExplainerExternalLink,
    ExplainerInfoBlock,
    ExplainerSection,
} from '@maybe-finance/client/shared'

const Em = ({ children }: { children: ReactNode }) => (
    <em className="not-italic text-gray-25">{children}</em>
)

export function BadDebt(): JSX.Element {
    const scrollContainer = useRef<HTMLDivElement>(null)

    const definition = useRef<HTMLDivElement>(null)
    const howAreWeGettingThisValue = useRef<HTMLDivElement>(null)
    const resources = useRef<HTMLDivElement>(null)

    return (
        <div className="flex flex-col w-full h-full">
            <h5 className="px-4 font-display font-bold text-2xl">Bad debt</h5>
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
                            name: 'Resources',
                            elementRef: resources,
                        },
                    ]}
                />
            </div>
            <div ref={scrollContainer} className="grow px-4 pb-16 basis-px custom-gray-scroll">
                <ExplainerSection title="Definition" ref={definition}>
                    Bad debt is debt that provides no future value to you such as a personal loan or
                    credit card debt. Ideally this is <Em>less than 35%</Em>.
                    <ExplainerInfoBlock title="TL;DR">
                        Debt that's not building wealth
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
                            All liabilities - [Liability type = investment or property]
                        </span>
                    </ExplainerInfoBlock>
                </ExplainerSection>

                <ExplainerSection title="Resources" ref={resources}>
                    <ExplainerExternalLink
                        icon={RiMicLine}
                        href="https://maybe.co/podcast/6-should-you-invest-more-or-pay-off-debt"
                    >
                        Podcast episode on investing vs. paying debt
                    </ExplainerExternalLink>
                    <ExplainerExternalLink
                        icon={RiArticleLine}
                        href="https://maybe.co/articles/ask-the-advisor-invest-more-or-pay-off-debt"
                    >
                        Article from the Maybe blog on investing vs. paying debt
                    </ExplainerExternalLink>
                    <ExplainerExternalLink
                        icon={RiArticleLine}
                        href="https://maybe.co/articles/asset-allocation-and-how-to-use-it-to-reach-your-financial-goals"
                    >
                        Article from the Maybe blog on asset allocation
                    </ExplainerExternalLink>
                </ExplainerSection>
            </div>
        </div>
    )
}
