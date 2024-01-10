import { render, screen } from '@testing-library/react'
import FormGroup from './FormGroup'

describe('FormGroup', () => {
    describe('when rendered with children', () => {
        it('should wrap and display the children', () => {
            const component = render(
                <FormGroup>
                    <label htmlFor="input">Hello, World!</label>
                    <input type="text" id="input" />
                </FormGroup>
            )

            expect(screen.getByText('Hello, World!')).toBeInTheDocument()
            expect(screen.getByLabelText('Hello, World!')).toBeInTheDocument()
            expect(component).toMatchSnapshot()
        })
    })
})
