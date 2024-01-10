import { render, screen } from '@testing-library/react'
import SmallDecimals from './SmallDecimals'

describe('SmallDecimals', () => {
    describe('when using the correct value format', () => {
        it('formats decimals', () => {
            render(<SmallDecimals value="$123,456.13" />)

            expect(screen.getByTestId('decimals').textContent).toBe('.13')
        })
    })
    describe('when not using the correct value format', () => {
        it('does not apply decimals formatting but render value #1', () => {
            render(<SmallDecimals value="something" />)

            expect(screen.queryByTestId('decimals')).toBeFalsy()
            expect(screen.getByText('something')).toBeTruthy()
        })

        it('does not apply decimals formatting but render value #2', () => {
            render(<SmallDecimals value="100" />)

            expect(screen.queryByTestId('decimals')).toBeFalsy()
            expect(screen.getByText('100')).toBeTruthy()
        })
    })
})
