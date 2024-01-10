import type { Story, Meta } from '@storybook/react'
import { useRef } from 'react'

import { IndexTabs } from '.'

export default {
    title: 'Components/IndexTabs',
    argTypes: {},
    args: {},
} as Meta

export const Base: Story = (_args) => {
    const scrollContainer = useRef<HTMLDivElement>(null)
    const section1 = useRef<HTMLDivElement>(null)
    const section2 = useRef<HTMLDivElement>(null)
    const section3 = useRef<HTMLDivElement>(null)

    return (
        <>
            <IndexTabs
                scrollContainer={scrollContainer}
                sections={[
                    {
                        name: 'Section 1',
                        elementRef: section1,
                    },
                    {
                        name: 'Section 2',
                        elementRef: section2,
                    },
                    {
                        name: 'Section 3',
                        elementRef: section3,
                    },
                ]}
            />
            <div className="h-24 w-96 mt-2 overflow-y-auto text-white" ref={scrollContainer}>
                <div className="mb-4" ref={section1}>
                    <h1 className="uppercase font-bold">Section 1</h1>
                    <p className="text-gray-50">
                        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
                        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
                        quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
                        consequat.
                    </p>
                </div>
                <div className="mb-4" ref={section2}>
                    <h1 className="uppercase font-bold">Section 2</h1>
                    <p className="text-gray-50">
                        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
                        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
                        quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
                        consequat.
                    </p>
                </div>
                <div className="mb-4" ref={section3}>
                    <h1 className="uppercase font-bold">Section 3</h1>
                    <p className="text-gray-50">
                        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
                        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
                        quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
                        consequat.
                    </p>
                </div>
            </div>
        </>
    )
}
