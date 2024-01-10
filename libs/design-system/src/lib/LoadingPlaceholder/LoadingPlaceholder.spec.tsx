import { render } from '@testing-library/react'
import { LoadingPlaceholder } from './'

describe('LoadingPlaceholder', () => {
    it('should render properly', () => {
        const component = render(<LoadingPlaceholder />)

        expect(component).toMatchSnapshot()
    })
})
