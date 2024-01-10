import { render, screen } from '@testing-library/react'
import Breadcrumb from './Breadcrumb'

describe('Breadcrumbs', () => {
    describe('when rendered with text and hrefs', () => {
        it('should display the linked text', () => {
            const component = render(
                <Breadcrumb.Group>
                    <Breadcrumb href="/example">Example</Breadcrumb>
                    <Breadcrumb href="/example2">Example 2</Breadcrumb>
                </Breadcrumb.Group>
            )

            expect(screen.getByText('Example')).toBeInTheDocument()
            expect(screen.getByText('Example 2')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })
})
