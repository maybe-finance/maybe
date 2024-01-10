import Decimal from 'decimal.js'
import { confidenceInterval, mean, stddev, variance, quantiles, quantilesBy } from './stats-utils'

const d = (x: Decimal.Value) => new Decimal(x)

describe('stats', () => {
    it.each`
        data             | mean | variance | stddev | ci
        ${[1, 7, 9, 15]} | ${8} | ${25}    | ${5}   | ${[3.1, 12.9]}
    `('calculates data=$data μ=$mean σ²=$variance σ=$stddev ci=$ci', (x) => {
        expect(mean(x.data)).toEqual(d(x.mean))
        expect(variance(x.data)).toEqual(d(x.variance))
        expect(stddev(x.data)).toEqual(d(x.stddev))
        expect(confidenceInterval(x.data)).toEqual(x.ci.map(d))
    })

    it('calculates quantiles', () => {
        const res = quantiles([1, 3, 2, 5, 4], ['0', '0.1', '0.25', '0.5', '0.75', '0.9', '1'])

        expect(res).toHaveLength(7)
        expect(res).toEqual([1, 1, 2, 3, 4, 5, 5].map(d))
    })

    it('calculates median using average of middle 2 elements', () => {
        const res = quantiles([1, 2, 3, 4], ['0.5'])

        expect(res[0]).toEqual(d(2.5))
    })

    it('calcualtes quantiles by property', () => {
        const data = [{ a: 1 }, { a: 2 }, { a: 3 }, { a: 4 }]

        const res = quantilesBy(data, (item) => new Decimal(item.a), ['0.5'])

        expect(res[0]).toEqual(data[1])
    })
})
