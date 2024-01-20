import { IndexTabs } from '@maybe-finance/design-system'
import { useRef } from 'react'
import { ExplainerInfoBlock, ExplainerSection } from '@maybe-finance/client/shared'

export function Contributions(): JSX.Element {
    const scrollContainer = useRef<HTMLDivElement>(null)

    const definition = useRef<HTMLDivElement>(null)
    const howAreWeGettingThisValue = useRef<HTMLDivElement>(null)

    return (
        <div className="flex flex-col w-full h-full">
            <h5 className="px-4 font-display font-bold text-2xl">Contributions</h5>
            <div className="shrink-0 px-4 py-3">
                <IndexTabs
                    scrollContainer={scrollContainer}
                    sections={[
                        { name: 'Definition', elementRef: definition },
                        {
                            name: 'How are we getting this value?',
                            elementRef: howAreWeGettingThisValue,
                        },
                    ]}
                />
            </div>
            <div ref={scrollContainer} className="grow px-4 pb-16 basis-px custom-gray-scroll">
                <ExplainerSection title="Definition" ref={definition}>
                    This is how much you&rsquo;ve invested into your portfolio, along with a monthly
                    average.
                    <ExplainerInfoBlock title="TL;DR">
                        It&rsquo;s your &ldquo;how much have I invested?&rdquo; number
                    </ExplainerInfoBlock>
                </ExplainerSection>

                <ExplainerSection
                    title="How are we getting this value?"
                    ref={howAreWeGettingThisValue}
                >
                    Is what you&rsquo;re probably asking when seeing that number. Well, below is the
                    formula we use:
                    <ExplainerInfoBlock title="Formula">
                        <span className="font-mono italic">Total Deposits - Total Withdrawals</span>
                    </ExplainerInfoBlock>
                </ExplainerSection>
            </div>
        </div>
    )
}
