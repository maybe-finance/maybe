import { calculatePercentChange, format } from './number-utils'

describe('number-utils', () => {
    describe('calculatePercentChange', () => {
        test.each([
            [0, 100, Infinity],
            [0, -100, -Infinity],
            [0, 0, 0],
            [100, 100, 0],
            [-100, -100, 0],
            [100, 200, 1],
            [200, 100, -0.5],
            [null, 100, NaN],
            [100, null, NaN],
            [null, null, NaN],
            [NaN, 100, NaN],
            [100, NaN, NaN],
            [NaN, NaN, NaN],
        ])('(%i, %i) === %s', (from, to, percentage) => {
            expect(calculatePercentChange(from, to)).toStrictEqual(percentage)
        })
    })

    describe('currency formatting edge cases', () => {
        test.each([
            [NaN, '--'],
            [Infinity, `∞`],
            [-Infinity, `-∞`],
            [undefined, '--'],
            [null, '--'],
            ['invalid number string', '--'],
        ])('input=%s output=%s', (value, expectedValue) => {
            expect(format(value, 'currency')).toStrictEqual(expectedValue)
        })
    })

    describe('percentage formatting edge cases', () => {
        test.each([
            [NaN, '--'],
            [Infinity, `∞%`],
            [-Infinity, `-∞%`],
            [undefined, '--'],
            [null, '--'],
            ['invalid number string', '--'],
        ])('input=%s output=%s', (value, expectedValue) => {
            expect(format(value, 'percent')).toStrictEqual(expectedValue)
        })
    })

    describe('currency format', () => {
        test.each([
            ['20', '$20.00', undefined],
            [20, '$20.00', undefined],
            [20.45, '$20.45', undefined],
            [20, '$20.00', undefined],
            [2000, '$2,000.00', undefined],
            [2000, '$2,000', { minimumFractionDigits: 0 }],
            [2000.2, '$2,000.2', { minimumFractionDigits: 0 }],
            [2000.25, '$2,000.25', { minimumFractionDigits: 0 }],
            [2000.25, '$2,000', { minimumFractionDigits: 0, maximumFractionDigits: 0 }],
        ])('input=%s output=%s', (value, expectedValue, options) => {
            expect(format(value, 'currency', options)).toStrictEqual(expectedValue)
        })
    })

    describe('short currency format', () => {
        test.each([
            ['20', '$20.00', undefined],
            [20, '$20.00', undefined],
            [20.2, '$20.20', { minimumFractionDigits: 2, maximumFractionDigits: 2 }],
            [20, '$20.0', { minimumFractionDigits: 1, maximumFractionDigits: 2 }],
            [20.2, '$20.20', undefined],
            [20000, '$20k', undefined],
            [-20000, '-$20k', undefined],
            [-28000, '-$28k', undefined],
            [-28000, '-$28k', { minimumFractionDigits: 2, maximumFractionDigits: 2 }],
            [-28500, '-$28.5k', { minimumFractionDigits: 2, maximumFractionDigits: 2 }],
            [-28000, '-$28k', { minimumFractionDigits: 1, maximumFractionDigits: 2 }],
            [-28500, '-$28.5k', { minimumFractionDigits: 1, maximumFractionDigits: 2 }],
            [-28550, '-$28.55k', { minimumFractionDigits: 1, maximumFractionDigits: 2 }],
            [-28550, '-$28.6k', { minimumFractionDigits: 1, maximumFractionDigits: 1 }],
            [-28550, '-$29k', { minimumFractionDigits: 0, maximumFractionDigits: 0 }],
            [2_000_000, '$2m', undefined],
            [2_000_000, '$2m', undefined],
            [2_000_000_000, '$2b', undefined],
            [2_500_000_000, '$2.5b', undefined],
            [2_540_000_000, '$2.54b', undefined],
            [2_560_000_000, '$2.56b', undefined],
            [2_560_000_000, '$2.56b', { minimumFractionDigits: 2, maximumFractionDigits: 2 }],
            [2_500_000_000, '$2.5b', { minimumFractionDigits: 2, maximumFractionDigits: 2 }],
            [0, '$0.00', undefined],
        ])('input=%s output=%s', (value, expectedValue, options) => {
            expect(format(value, 'short-currency', options)).toStrictEqual(expectedValue)
        })
    })

    describe('percent format', () => {
        test.each([
            ['0.02', '+2%', undefined],
            [0.02, '+2%', undefined],
            ['-0.02', '-2%', undefined],
            [-0.02, '-2%', undefined],
            [20, '+2,000%', undefined],
            [20000, '+2,000,000%', undefined],
            [-20000, '-2,000,000%', undefined],
            [0, '0%', undefined],
        ])('input=%s output=%s', (value, expectedValue, options) => {
            expect(format(value, 'percent', options)).toStrictEqual(expectedValue)
        })
    })
})
