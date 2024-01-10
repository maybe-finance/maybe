import { render, screen } from '@testing-library/react'
import { Slider } from '.'

describe('Slider', () => {
    // Limited test cases we can do here without implementing a rather complex drag-n-drop test case
    it('should render correctly', () => {
        const onChangeMock = jest.fn()
        const component = render(<Slider initialValue={[10]} onChange={onChangeMock} />)

        const handle = screen.getByTestId('handle-0')
        expect(handle).toBeInTheDocument()

        // We only provided 1 handle in the `initialValue` array, so this shouldn't be there
        expect(screen.queryByTestId('handle-1')).not.toBeInTheDocument()

        expect(screen.getByTestId('slider-track')).toBeInTheDocument()
        expect(component).toMatchSnapshot()
    })
})
