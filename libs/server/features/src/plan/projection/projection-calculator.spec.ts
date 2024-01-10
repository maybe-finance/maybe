import Decimal from 'decimal.js'
import { DateTime } from 'luxon'
import { AssetValue } from './projection-value'
import { ProjectionCalculator } from './projection-calculator'

expect.extend({
    toEqualDecimal(
        received: Decimal.Value,
        expected: Decimal.Value,
        threshold: Decimal.Value = '0.01'
    ) {
        const pass = Decimal.sub(received, expected).abs().lt(threshold)
        return {
            pass,
            message: () =>
                `expected ${this.utils.printReceived(received)} ${
                    pass ? `not to be` : 'to be'
                } within ${threshold} of ${this.utils.printExpected(expected)}`,
        }
    },
})

interface CustomMatchers<R = unknown> {
    toEqualDecimal(expected: Decimal.Value, threshold?: Decimal.Value): R
}

/* eslint-disable */
declare global {
    namespace jest {
        interface Expect extends CustomMatchers {}
        interface Matchers<R> extends CustomMatchers<R> {}
        interface InverseAsymmetricMatchers extends CustomMatchers {}
    }
}
/* eslint-enable */

const calculator = new ProjectionCalculator()

describe('projection service', () => {
    it('simulates assets', () => {
        const series = calculator.calculate(
            {
                years: 30,
                assets: [
                    { id: 'stock', value: new AssetValue(800, 0.05) },
                    { id: 'bonds', value: new AssetValue(150, 0.02) },
                    { id: 'cash', value: new AssetValue(50, -0.2) },
                ],
                liabilities: [],
                events: [],
                milestones: [],
            },
            DateTime.fromISO('2022-01-01')
        )

        expect(series).toHaveLength(30)

        series.forEach((data) => {
            expect(data.assets).toHaveLength(3)
        })

        expect(series[0]).toMatchObject({ year: 2022, netWorth: expect.toEqualDecimal(1000) })
        expect(series[1]).toMatchObject({ year: 2023, netWorth: expect.toEqualDecimal(1033) })
        expect(series[2]).toMatchObject({ year: 2024, netWorth: expect.toEqualDecimal(1067.09) })
        expect(series[29]).toMatchObject({ year: 2051, netWorth: expect.toEqualDecimal(2563.95) })
    })

    it('simulates liabilities', () => {
        const series = calculator.calculate(
            {
                years: 10,
                assets: [{ id: 'asset', value: new AssetValue(100) }],
                liabilities: [{ id: 'liability', value: new AssetValue(50) }],
                events: [],
                milestones: [],
            },
            DateTime.fromISO('2022-01-01')
        )

        expect(series).toHaveLength(10)

        series.forEach((data) => {
            expect(data.liabilities).toHaveLength(1)
        })

        expect(series[0]).toMatchObject({ year: 2022, netWorth: expect.toEqualDecimal(50) })
        expect(series[1]).toMatchObject({ year: 2023, netWorth: expect.toEqualDecimal(50) })
        expect(series[2]).toMatchObject({ year: 2024, netWorth: expect.toEqualDecimal(50) })
        expect(series[9]).toMatchObject({ year: 2031, netWorth: expect.toEqualDecimal(50) })
    })

    it('simulates events', () => {
        const series = calculator.calculate(
            {
                years: 30,
                assets: [
                    { id: 'stock', value: new AssetValue(800, 0.05) },
                    { id: 'bonds', value: new AssetValue(150, 0.02) },
                    { id: 'cash', value: new AssetValue(50, -0.03) },
                ],
                liabilities: [],
                events: [
                    { id: 'salary', value: new AssetValue(2000) },
                    { id: 'rent', value: new AssetValue(-1000) },
                    { id: 'windfall', value: new AssetValue(100), start: 2025, end: 2025 },
                ],
                milestones: [],
            },
            DateTime.fromISO('2022-01-01')
        )

        expect(series).toHaveLength(30)
        expect(series[0]).toMatchObject({ year: 2022, netWorth: expect.toEqualDecimal(2000) })
        expect(series[1]).toMatchObject({ year: 2023, netWorth: expect.toEqualDecimal(3083) })
        expect(series[2]).toMatchObject({ year: 2024, netWorth: expect.toEqualDecimal(4210.94) })
        expect(series[2].events).toHaveLength(2)
        expect(series[3]).toMatchObject({ year: 2025, netWorth: expect.toEqualDecimal(5485.7) })
        expect(series[3].events).toHaveLength(3)
        expect(series[4]).toMatchObject({ year: 2026, netWorth: expect.toEqualDecimal(6713.36) })
        expect(series[4].events).toHaveLength(2)
    })

    it('simulates milestones', () => {
        const series = calculator.calculate(
            {
                years: 30,
                assets: [
                    { id: 'stock', value: new AssetValue(800, 0.05) },
                    { id: 'bonds', value: new AssetValue(150, 0.02) },
                    { id: 'cash', value: new AssetValue(50, -0.03) },
                ],
                liabilities: [],
                events: [
                    { id: 'salary', value: new AssetValue(2000), end: 'fi' },
                    { id: 'rent', value: new AssetValue(-1000) },
                    {
                        id: 'fi-spend',
                        value: new AssetValue(-100),
                        start: 'fi',
                        end: 'retirement',
                    },
                    { id: 'retirement-spend', value: new AssetValue(-100), start: 'retirement' },
                ],
                milestones: [
                    { id: 'fi', type: 'net-worth', expenseMultiple: 25, expenseYears: 3 },
                    { id: 'retirement', type: 'year', year: 2050 },
                ],
            },
            DateTime.fromISO('2022-01-01')
        )

        expect(series).toHaveLength(30)
        expect(series[0]).toMatchObject({ year: 2022, netWorth: expect.toEqualDecimal(2000) })
        expect(series[1]).toMatchObject({ year: 2023, netWorth: expect.toEqualDecimal(3083) })
        expect(series[2]).toMatchObject({ year: 2024, netWorth: expect.toEqualDecimal(4210.94) })

        // year before `fi` milestone
        expect(series[15].events.map((e) => e.id)).toEqual(['salary', 'rent'])
        // year of `fi` milestone
        expect(series[16].events.map((e) => e.id)).toEqual(['salary', 'rent'])
        expect(series[16].milestones.map((m) => m.id)).toEqual(['fi'])
        // year after `fi` milestone
        expect(series[17].events.map((e) => e.id)).toEqual(['rent', 'fi-spend'])

        // year before `retirement` milestone
        expect(series[27].events.map((e) => e.id)).toEqual(['rent', 'fi-spend'])
        // year of `retirement` milestone
        expect(series[28].events.map((e) => e.id)).toEqual(['rent', 'fi-spend', 'retirement-spend'])
        expect(series[28].milestones.map((m) => m.id)).toEqual(['retirement'])
        // year after `retirement` milestone
        expect(series[29].events.map((e) => e.id)).toEqual(['rent', 'retirement-spend'])
    })

    it('events end in same year as referenced milestone', () => {
        const series = calculator.calculate(
            {
                years: 10,
                assets: [],
                liabilities: [],
                events: [{ id: 'income', value: new AssetValue(1_000), end: 'retirement' }],
                milestones: [{ id: 'retirement', type: 'year', year: 2025 }],
            },
            DateTime.fromISO('2022-01-01')
        )

        // 2024
        expect(series[2].events).toHaveLength(1)
        expect(series[2].milestones).toHaveLength(0)

        // 2025
        expect(series[3].events).toHaveLength(1)
        expect(series[3].milestones).toHaveLength(1)

        // 2026
        expect(series[4].events).toHaveLength(0)
        expect(series[4].milestones).toHaveLength(0)
    })
})
