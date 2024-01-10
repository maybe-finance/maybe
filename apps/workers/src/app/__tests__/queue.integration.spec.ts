// =====================================================
// Keep these imports above the rest to avoid errors
// =====================================================
import type { SharedType } from '@maybe-finance/shared'
import type { AccountsGetResponse, TransactionsGetResponse } from 'plaid'
import type { AccountConnection, User } from '@prisma/client'
import { TestUtil } from '@maybe-finance/shared'
import { PlaidTestData } from '../../../../../tools/test-data'
import { Prisma } from '@prisma/client'
import prisma from '../lib/prisma'
import { default as _plaid } from '../lib/plaid'
import nock from 'nock'
import { DateTime } from 'luxon'
import { resetUser } from './helpers/user.test-helper'

// Import the workers process
import '../../main'
import { queueService, securityPricingService } from '../lib/di'

jest.mock('plaid')

// For TypeScript support
const plaid = jest.mocked(_plaid)

let user: User | null
let connection: AccountConnection

// When debugging, we don't want the tests to time out
if (process.env.IS_VSCODE_DEBUG === 'true') {
    jest.setTimeout(100000)
}

beforeAll(() => {
    nock.disableNetConnect()

    nock('https://api.polygon.io')
        .get((uri) => uri.includes('v2/aggs/ticker/AAPL/range/1/day'))
        .reply(200, PlaidTestData.AAPL)
        .persist()

    nock('https://api.polygon.io')
        .get((uri) => uri.includes('v2/aggs/ticker/WMT/range/1/day'))
        .reply(200, PlaidTestData.WMT)
        .persist()

    nock('https://api.polygon.io')
        .get((uri) => uri.includes('v2/aggs/ticker/VOO/range/1/day'))
        .reply(200, PlaidTestData.VOO)
        .persist()
})

beforeEach(async () => {
    jest.clearAllMocks()

    user = await resetUser(prisma)

    connection = await prisma.accountConnection.create({
        data: {
            name: 'Chase Test',
            type: 'plaid' as SharedType.AccountConnectionType,
            plaidItemId: 'test-plaid-item-workers',
            plaidInstitutionId: 'ins_3',
            plaidAccessToken:
                'U2FsdGVkX1+WMq9lfTS9Zkbgrn41+XT1hvSK5ain/udRPujzjVCAx/lyPG7EumVZA+nVKXPauGwI+d7GZgtqTA9R3iCZNusU6LFPnmFOCE4=', // need correct encoding here
            userId: user.id,
            syncStatus: 'PENDING',
        },
    })
})

describe('Message queue tests', () => {
    it('Creates the correct number of queues', () => {
        expect(queueService.allQueues.map((q) => q.name)).toEqual([
            'sync-user',
            'sync-account',
            'sync-account-connection',
            'sync-security',
            'purge-user',
            'sync-institution',
            'send-email',
        ])
    })

    it('Should handle sync errors', async () => {
        const syncQueue = queueService.getQueue('sync-account-connection')

        plaid.accountsGet.mockRejectedValueOnce('forced error for Jest tests')

        await syncQueue.add('sync-connection', { accountConnectionId: connection.id })

        const updatedConnection = await prisma.accountConnection.findUnique({
            where: { id: connection.id },
        })

        expect(plaid.accountsGet).toHaveBeenCalledTimes(1)
        expect(updatedConnection?.status).toEqual('ERROR')
    })

    it('Should run all sync-account-connection queue jobs', async () => {
        const syncQueue = queueService.getQueue('sync-account-connection')

        let cnx = await prisma.accountConnection.findUnique({ where: { id: connection.id } })

        expect(cnx?.status).toEqual('OK')
        expect(cnx?.syncStatus).toEqual('PENDING')

        await syncQueue.add('sync-connection', { accountConnectionId: connection.id })

        cnx = await prisma.accountConnection.findUnique({
            where: { id: connection.id },
        })

        expect(cnx?.syncStatus).toEqual('IDLE')
    })

    xit('Should sync connected transaction account', async () => {
        const syncQueue = queueService.getQueue('sync-account-connection')

        // Mock will return a basic banking checking account
        plaid.accountsGet.mockResolvedValueOnce(
            TestUtil.axiosSuccess<AccountsGetResponse>({
                accounts: [PlaidTestData.checkingAccount],
                item: PlaidTestData.item,
                request_id: 'bkVE1BHWMAZ9Rnr',
            }) as any
        )

        plaid.transactionsGet.mockResolvedValueOnce(
            TestUtil.axiosSuccess<TransactionsGetResponse>({
                accounts: [PlaidTestData.checkingAccount],
                transactions: PlaidTestData.checkingTransactions,
                item: PlaidTestData.item,
                total_transactions: PlaidTestData.checkingTransactions.length,
                request_id: '45QSn',
            }) as any
        )

        await syncQueue.add('sync-connection', { accountConnectionId: connection.id })

        expect(plaid.accountsGet).toHaveBeenCalledTimes(1)
        expect(plaid.transactionsGet).toHaveBeenCalledTimes(1)

        const item = await prisma.accountConnection.findUniqueOrThrow({
            where: { id: connection.id },
            include: {
                accounts: {
                    include: {
                        balances: {
                            where: PlaidTestData.testDates.prismaWhereFilter,
                            orderBy: { date: 'asc' },
                        },
                        transactions: true,
                        holdings: true,
                        valuations: true,
                        investmentTransactions: true,
                    },
                },
            },
        })

        expect(item.accounts).toHaveLength(1)

        const [account] = item.accounts

        expect(account.transactions).toHaveLength(PlaidTestData.checkingTransactions.length)
        expect(account.balances.map((b) => b.balance)).toEqual(
            [
                3630,
                5125,
                5125,
                5125,
                5125,
                5125,
                5125,
                5125,
                5125,
                5125,
                5115,
                5115,
                5115,
                5089.45,
                5089.45,
                PlaidTestData.checkingAccount.balances.current!,
            ].map((v) => new Prisma.Decimal(v))
        )
        expect(account.holdings).toHaveLength(0)
        expect(account.valuations).toHaveLength(0)
        expect(account.investmentTransactions).toHaveLength(0)
    })

    it('Should sync valid security prices', async () => {
        const security = await prisma.security.create({
            data: {
                name: 'Walmart Inc.',
                symbol: 'WMT',
                cusip: '93114210310',
                pricingLastSyncedAt: new Date(),
            },
        })

        await securityPricingService.sync(security)

        const prices = await prisma.securityPricing.findMany({
            where: { securityId: security.id },
            orderBy: { date: 'asc' },
        })

        expect(prices).toHaveLength(PlaidTestData.WMT.results.length)

        expect(
            prices.map((p) => ({
                date: DateTime.fromJSDate(p.date, { zone: 'utc' }).toISODate(),
                price: p.priceClose.toNumber(),
            }))
        ).toEqual(
            PlaidTestData.WMT.results.map((p) => ({
                date: DateTime.fromMillis(p.t, { zone: 'utc' }).toISODate(),
                price: p.c,
            }))
        )
    })
})
