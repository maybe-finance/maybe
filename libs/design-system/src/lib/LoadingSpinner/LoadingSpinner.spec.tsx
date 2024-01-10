import { render, screen } from '@testing-library/react'
import { LoadingSpinner } from './'

describe('LoadingSpinner', () => {
    it('should render properly', () => {
        const component = render(<LoadingSpinner />)

        expect(screen.getByRole('img')).toBeInTheDocument()
        expect(component).toMatchSnapshot()
    })
})
