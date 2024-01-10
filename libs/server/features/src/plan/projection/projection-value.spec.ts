import { Decimal } from 'decimal.js'
import { AssetValue } from './projection-value'

const d = (n: Decimal.Value) => new Decimal(n)

describe('asset value', () => {
    it('never generates negative values', () => {
        const value = new AssetValue(1, -2)
        expect(value.initialValue).toEqual(d(1))

        const next = value.next()
        expect(next).toEqual(d(0))
        expect(value.next(next)).toEqual(d(0))
    })
})
