import type { AxiosInstance } from 'axios'
import { PrismaClient, type Account, type AccountConnection, type User } from '@prisma/client'
import { DateTime } from 'luxon'
import {
    InvestmentTransactionBalanceSyncStrategy,
    AccountQueryService,
    AccountService,
    type IBalanceSyncStrategyFactory,
} from '@maybe-finance/server/features'
import { InMemoryQueueFactory, PgService, type IQueueFactory } from '@maybe-finance/server/shared'
import { createLogger, transports } from 'winston'
import isCI from 'is-ci'
import nock from 'nock'
import Decimal from 'decimal.js'
import { startServer, stopServer } from './utils/server'
import { getAxiosClient } from './utils/axios'
import { resetUser } from './utils/user'
import { createTestInvestmentAccount } from './utils/account'
import { default as _plaid } from '../lib/plaid'

jest.mock('../middleware/validate-plaid-jwt.ts')
jest.mock('bull')
jest.mock('plaid')

const prisma = new PrismaClient()

// For TypeScript support
const plaid = jest.mocked(_plaid) // eslint-disable-line

const auth0Id = isCI ? 'auth0|61afd38f678a0c006895f046' : 'auth0|61afd340678a0c006895f000'
let axios: AxiosInstance
let user: User

// When debugging, we don't want the tests to time out
if (process.env.IS_VSCODE_DEBUG === 'true') {
    jest.setTimeout(100000)
}

beforeEach(async () => {
    // Clears old user and data, creates new user
    user = await resetUser(auth0Id)
})

describe('/v1/accounts API', () => {
    beforeAll(async () => {
        await startServer()
        axios = await getAxiosClient()

        nock.disableNetConnect()
        nock.enableNetConnect((host) => {
            return (
                host.includes('127.0.0.1') ||
                host.includes('maybe-finance-development.us.auth0.com')
            )
        })
    }, 10_000)

    afterAll(async () => {
        await stopServer()
    })

    it('Can create, retrieve, and delete account', async () => {
        const testPurchaseDate = DateTime.utc().startOf('day').minus({ days: 5 })

        const startValue = 20_000
        const endValue = 21_000

        const res = await axios.post<Account>(`/accounts`, {
            type: 'VEHICLE',
            name: 'Test account',
            categoryUser: 'vehicle',
            startDate: testPurchaseDate.toISODate(),
            valuations: {
                originalBalance: 20_000,
                currentBalance: 21_000,
                currentDate: DateTime.utc().startOf('day').toISODate(),
            },
            vehicleMeta: {
                track: false,
                make: 'Honda',
                model: 'Civic',
                year: 2010,
            },
        })

        expect(res.status).toEqual(200)

        // Replace this with /accounts/:id once PR 169 is merged
        const getAccountsResponse = await axios.get<{
            connections: AccountConnection
            accounts: Account[]
        }>(`/accounts`)

        expect(getAccountsResponse.status).toEqual(200)

        const account = getAccountsResponse.data.accounts[0]

        expect(account).toMatchObject({
            startDate: testPurchaseDate.toJSDate(),
            type: 'VEHICLE',
            provider: 'user',
            classification: 'asset',
            category: 'vehicle',
            subcategory: 'other',
            accountConnectionId: null,
            userId: user!.id,
            name: 'Test account',
            mask: null,
            isActive: true,
            syncStatus: 'IDLE',
            plaidType: null,
            plaidSubtype: null,
            plaidAccountId: null,
            plaidLiability: null,
            currencyCode: 'USD',
            currentBalance: new Decimal(21_000),
            availableBalance: null,
            vehicleMeta: {
                track: false,
                make: 'Honda',
                model: 'Civic',
                year: 2010,
            },
            propertyMeta: null,
        })

        const balanceResponse = await axios.get(
            `/accounts/${
                account.id
            }/balances?start=${testPurchaseDate.toISODate()}&end=${DateTime.utc().toISODate()}`
        )
        const balances = balanceResponse.data.series.data

        const interpolationStep = (endValue - startValue) / 5 // 5 intervals between start/end

        expect(balances).toHaveLength(6)
        expect(balances[0].balance).toEqual(new Decimal(startValue))
        expect(balances[2].balance).toEqual(new Decimal(startValue + interpolationStep * 2))
        expect(balances[balances.length - 1].balance).toEqual(new Decimal(endValue))

        const deleteResponse = await axios.delete(`/accounts/${account.id}`)
        expect(deleteResponse.status).toEqual(200)
    })
})

describe('account service', () => {
    let accountService: AccountService

    beforeEach(() => {
        const logger = createLogger({ transports: [new transports.Console()] })
        const balanceSyncStrategyFactory: IBalanceSyncStrategyFactory = {
            for: () => new InvestmentTransactionBalanceSyncStrategy(logger, prisma),
        }
        const queueFactory: IQueueFactory = new InMemoryQueueFactory()

        accountService = new AccountService(
            logger,
            prisma,
            new AccountQueryService(logger, new PgService(logger)),
            queueFactory.createQueue('sync-account'),
            queueFactory.createQueue('sync-account-connection'),
            balanceSyncStrategyFactory
        )
    })

    describe('account returns', () => {
        it('calculates contributions for account w/ full history', async () => {
            const account = await createTestInvestmentAccount(prisma, user, 'portfolio-1')

            const series = await accountService.getReturns(account.id, '2021-12-30', '2022-03-31')

            const data = (date: string) => series.find((b) => b.date === date)!

            expect(series).toHaveLength(92)
            expect(data('2021-12-30').account.contributions?.toNumber()).toEqual(0)
            expect(data('2021-12-31').account.contributions?.toNumber()).toEqual(5000)
            expect(data('2022-02-04').account.contributions?.toNumber()).toEqual(5000)
            expect(data('2022-02-05').account.contributions?.toNumber()).toEqual(4000)
            expect(data('2022-03-07').account.contributions?.toNumber()).toEqual(4000)
            expect(data('2022-03-08').account.contributions?.toNumber()).toEqual(8000)
            expect(data('2022-03-31').account.contributions?.toNumber()).toEqual(8000)
        })

        it('calculates contributions for account w/ partial history', async () => {
            const account = await createTestInvestmentAccount(prisma, user, 'portfolio-2')

            const series = await accountService.getReturns(account.id, '2022-08-01', '2022-08-24')

            expect(series).toHaveLength(24)
            expect(series.map((d) => d.account.contributions?.toNumber())).toEqual([
                // 8/1 -> 8/7
                0, 0, 0, 0, 0, 0, 0,
                // 8/8 -> 8/14
                0, 0, 2_000, 2_000, 7_000, 7_000, 7_000,
                // 8/15 -> 8/21
                9_000, 9_000, 9_000, 7_000, 7_000, 7_000, 7_000,
                // 8/22 -> 8/24
                8_000, 8_000, 8_000,
            ])
        })

        it('calculates returns for account w/ full history', async () => {
            const account = await createTestInvestmentAccount(prisma, user, 'portfolio-1')

            await accountService.syncBalances(account.id)

            const series = await accountService.getReturns(
                account.id,
                '2021-12-30', // any dates prior to the start date should result in 0% return
                '2022-04-01'
            )

            /**
             * Use Google Sheet and copy data from return column and paste into file
             * https://docs.google.com/spreadsheets/d/1xL1MnvLhvVqea9JfEO_FYjcv9AIfkz5NnwIh5nMMZRg/edit?usp=sharing
             *
             * with open('/path/to/file', 'r') as fp:
             *   s = fp.read()
             *
             * s.replace('\n', ',')
             */
            const expectedReturns = [
                0.0, 0.0, 0.0, 0.0, 0.001, 0.002, 0.002, 0.002, 0.002, 0.002, 0.002, 0.002, 0.002,
                0.004, 0.008, 0.008, 0.008, 0.008, 0.008, 0.008, 0.008, 0.008, 0.008, 0.008, 0.008,
                0.008, 0.008, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004, 0.004,
                0.005, 0.005, 0.0195, 0.0155, 0.0155, 0.0155, 0.0155, 0.0155, 0.0155, 0.0155,
                0.0155, 0.0155, 0.023, 0.023, 0.023, 0.023, 0.023, 0.023, 0.023, 0.031, 0.031,
                0.031, 0.031, 0.0335, 0.0335, 0.036, 0.036, 0.036, 0.036, 0.036, 0.036, 0.018,
                0.0213, 0.0481, 0.0738, 0.0803, 0.0803, 0.0803, 0.0503, 0.0503, 0.0503, 0.0503,
                0.0503, 0.0503, 0.0503, 0.0503, 0.0503, 0.0353, 0.0353, 0.0353, 0.0353, 0.0353,
                0.0578, 0.0578, 0.0578, 0.0578,
            ]

            expect(series.map((d) => d.account.rateOfReturn.toNumber())).toEqual(expectedReturns)
        })

        it('calculates returns and contributions for partial history of account', async () => {
            const account = await createTestInvestmentAccount(prisma, user, 'portfolio-1')

            await accountService.syncBalances(account.id)

            const series = await accountService.getReturns(
                account.id,
                '2022-03-04', // any dates prior to the start date should result in 0% return
                '2022-03-15'
            )

            /**
             * https://docs.google.com/spreadsheets/d/1xL1MnvLhvVqea9JfEO_FYjcv9AIfkz5NnwIh5nMMZRg/edit?usp=sharing
             * (see "Historical Balances" column AI)
             */
            const expectedReturns = [
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0063, 0.0582, 0.1076, 0.1202, 0.1202, 0.1202, 0.0623,
            ]

            const expectedCumulativeContributions = [
                4000, 4000, 4000, 4000, 8000, 8000, 8000, 8000, 8000, 8000, 8000, 8000,
            ]

            const expectedPeriodContributions = [
                0, 0, 0, 0, 4000, 4000, 4000, 4000, 4000, 4000, 4000, 4000,
            ]

            expect(series.map((d) => d.account.rateOfReturn.toNumber())).toEqual(expectedReturns)
            expect(series.map((d) => d.account.contributions?.toNumber())).toEqual(
                expectedCumulativeContributions
            )
            expect(series.map((d) => d.account.contributionsPeriod?.toNumber())).toEqual(
                expectedPeriodContributions
            )
        })
    })
})
