import { fireEvent, render, screen } from '@testing-library/react'
import { Tab } from './'

// Not tested too thoroughly, most logic is covered by Headless UI base
describe('Tab', () => {
    it('should render correctly', () => {
        const component = render(
            <Tab.Group>
                <Tab.List>
                    <Tab>Tab 1</Tab>
                    <Tab>Tab 2</Tab>
                </Tab.List>
                <Tab.Panels>
                    <Tab.Panel>Content 1</Tab.Panel>
                    <Tab.Panel>Content 2</Tab.Panel>
                </Tab.Panels>
            </Tab.Group>
        )

        expect(screen.getByText('Tab 1')).toBeInTheDocument()
        expect(screen.queryByText('Content 1')).toBeInTheDocument()
        expect(component).toMatchSnapshot()
    })

    describe('when toggled', () => {
        it('should render the correct panel', () => {
            render(
                <Tab.Group>
                    <Tab.List>
                        <Tab>Tab 1</Tab>
                        <Tab>Tab 2</Tab>
                    </Tab.List>
                    <Tab.Panels>
                        <Tab.Panel>Content 1</Tab.Panel>
                        <Tab.Panel>Content 2</Tab.Panel>
                    </Tab.Panels>
                </Tab.Group>
            )

            // Content 1 visible, Content 2 hidden
            expect(screen.getByText('Content 1')).toBeInTheDocument()
            expect(screen.queryByText('Content 2')).not.toBeInTheDocument()

            fireEvent.click(screen.getByText('Tab 2'))

            // Content 2 visible, content 1 hidden
            expect(screen.getByText('Content 2')).toBeInTheDocument()
            expect(screen.queryByText('Content 1')).not.toBeInTheDocument()
        })
    })
})
