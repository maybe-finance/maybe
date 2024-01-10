import { render, screen } from '@testing-library/react'
import { useRef } from 'react'
import { IndexTabs } from './'

const Example = () => {
    const scrollContainer = useRef<HTMLDivElement>(null)
    const section1 = useRef<HTMLDivElement>(null)
    const section2 = useRef<HTMLDivElement>(null)

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
                ]}
            />
            <div style={{ overflowY: 'auto', height: '400px' }} ref={scrollContainer}>
                <div ref={section1} style={{ height: '500px' }}>
                    Content 1
                </div>
                <div ref={section2} style={{ height: '500px' }}>
                    Content 2
                </div>
            </div>
        </>
    )
}

// Very light testing - it's challenging to mock/test all of the scroll interactions
describe('IndexTabs', () => {
    it('should render correctly', () => {
        const component = render(<Example />)

        expect(screen.getByText('Section 1')).toBeInTheDocument()
        expect(screen.queryByText('Content 1')).toBeInTheDocument()

        expect(screen.getByText('Section 2')).toBeInTheDocument()
        expect(screen.queryByText('Content 2')).toBeInTheDocument()

        expect(component).toMatchSnapshot()
    })
})
