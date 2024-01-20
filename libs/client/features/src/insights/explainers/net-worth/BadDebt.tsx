import { IndexTabs } from '@maybe-finance/design-system'
import type { ReactNode } from 'react'
import { useRef } from 'react'
import { ExplainerInfoBlock, ExplainerSection } from '@maybe-finance/client/shared'

const Em = ({ children }: { children: ReactNode }) => (
    <em className="not-italic text-gray-25">{children}</em>
)

export function BadDebt(): JSX.Element {
    const scrollContainer = useRef<HTMLDivElement>(null)

    const definition = useRef<HTMLDivElement>(null)
    const howAreWeGettingThisValue = useRef<HTMLDivElement>(null)

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
            </div>
        </div>
    )
}
