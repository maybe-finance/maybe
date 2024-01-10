import Decimal from 'decimal.js'
import { monteCarlo } from './monte-carlo'

const d = (x: Decimal.Value) => new Decimal(x)

describe('monte carlo', () => {
    it('simulates', () => {
        const results = monteCarlo(() => Math.random(), {
            n: 1_000,
        })

        expect(results).toHaveLength(1_000)
    })
})
