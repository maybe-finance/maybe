import { Router } from 'express'
import _ from 'lodash'
import type Decimal from 'decimal.js'
import type { ProjectionInput } from '@maybe-finance/server/features'
import { AssetValue, monteCarlo, ProjectionCalculator } from '@maybe-finance/server/features'
import { StatsUtil } from '@maybe-finance/shared'

const router = Router()

const params: Record<string, [Decimal.Value, Decimal.Value]> = {
    stocks: ['0.05', '0.186'],
    bonds: ['0.02', '0.052'],
    cash: ['-0.02', '0.05'],
    crypto: ['1.0', '1.0'],
    property: ['0.1', '0.2'],
    other: ['-0.02', '0'],
}

function getInput(scenario: string, randomized = false): ProjectionInput {
    const Value = (value, mean, stddev) => new AssetValue(value, mean, randomized ? stddev : 0)

    const scenarios: Record<string, ProjectionInput> = {
        portfolio_vizualizer: {
            years: 30,
            assets: [
                {
                    id: 'stock',
                    value: Value(800_000, ...params.stocks),
                },
                {
                    id: 'bonds',
                    value: Value(150_000, ...params.bonds),
                },
                {
                    id: 'cash',
                    value: Value(50_000, ...params.cash),
                },
            ],
            liabilities: [],
            events: [
                { id: 'income', value: new AssetValue(100_000), end: 2032 },
                { id: 'expenses', value: new AssetValue(-60_000) },
            ],
            milestones: [
                { id: 'retirement', type: 'net-worth', expenseMultiple: 25, expenseYears: 1 },
            ],
        },
        debug: {
            years: 56,
            assets: [
                {
                    id: 'cash',
                    value: Value('283221', ...params.cash),
                },
                {
                    id: 'other',
                    value: Value('221332', ...params.other),
                },
                {
                    id: 'property',
                    value: Value('1300000', ...params.property),
                },
                {
                    id: 'stocks',
                    value: Value('1421113', ...params.stocks),
                },
            ],
            liabilities: [],
            events: [
                {
                    id: '3',
                    value: new AssetValue('-10000', '0.01'),
                    start: 2022,
                    end: 2072,
                },
                {
                    id: '4',
                    value: new AssetValue('12000'),
                    start: 2050,
                    end: 2072,
                },
                {
                    id: '5',
                    value: new AssetValue('17148'),
                    start: 2050,
                    end: 2072,
                },
                {
                    id: '6',
                    value: new AssetValue('-120000', '0.01'),
                    start: 2022,
                    end: 2076,
                },
            ],
            milestones: [
                {
                    id: '2',
                    type: 'year',
                    year: 2057,
                },
            ],
        },
    }

    return scenarios[scenario]
}

router.post('/projections', (req, res) => {
    const calculator = new ProjectionCalculator()

    const scenario = 'debug'
    const N = 500
    const tiles = ['0.1', '0.25', '0.5', '0.75', '0.9']

    const inputTheo = getInput(scenario, false)
    const inputRandomized = getInput(scenario, true)

    const theo = calculator.calculate(inputTheo)
    const simulations = monteCarlo(() => calculator.calculate(inputRandomized), { n: N })

    const simulationsWithStats = _.zipWith(...simulations, (...series) => {
        const year = series[0].year
        const netWorths = series.map((d) => d.netWorth)

        return {
            year,
            percentiles: StatsUtil.quantiles(netWorths, tiles),
            successRate: StatsUtil.rateOf(netWorths, (nw) => nw.gt(0)),
            ci95: StatsUtil.confidenceInterval(netWorths),
            avg: StatsUtil.mean(netWorths),
            netWorths: _.sortBy(netWorths, (nw) => +nw),
            stddev: StatsUtil.stddev(netWorths),
        }
    })

    const simulationsByPercentile = tiles.map((percentile, idx) => ({
        percentile,
        simulation: simulationsWithStats.map(({ year, percentiles }) => ({
            year,
            netWorth: percentiles[idx],
        })),
    }))

    const result = {
        theo,
        simulations,
        simulationsWithStats,
        simulationsByPercentile,
    }

    // res.set('cache-control', 'public, max-age=60')
    res.status(200).json(result)
})

export default router
