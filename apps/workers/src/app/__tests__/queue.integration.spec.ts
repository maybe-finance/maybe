// =====================================================
// Keep these imports above the rest to avoid errors
// =====================================================
import type { SharedType } from '@maybe-finance/shared'
import { TellerGenerator } from 'tools/generators'
import type { AccountConnection, User } from '@prisma/client'
import prisma from '../lib/prisma'
import { default as _teller } from '../lib/teller'
import { resetUser } from './helpers/user.test-helper'
import { Interval } from 'luxon'

// Import the workers process
import '../../main'
import { queueService } from '../lib/di'

// For TypeScript support
jest.mock('../lib/teller')
const teller = jest.mocked(_teller)

let user: User | null
let connection: AccountConnection

// When debugging, we don't want the tests to time out
if (process.env.IS_VSCODE_DEBUG === 'true') {
    jest.setTimeout(100000)
}

beforeEach(async () => {
    jest.clearAllMocks()

    user = await resetUser(prisma)

    connection = await prisma.accountConnection.create({
        data: {
            name: 'Chase Test',
            type: 'teller' as SharedType.AccountConnectionType,
            tellerEnrollmentId: 'test-teller-item-workers',
            tellerInstitutionId: 'chase_test',
            tellerAccessToken:
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

        teller.getAccounts.mockRejectedValueOnce(new Error('forced error for Jest tests'))

        await syncQueue.add('sync-connection', { accountConnectionId: connection.id })

        const updatedConnection = await prisma.accountConnection.findUnique({
            where: { id: connection.id },
        })

        expect(teller.getAccounts).toHaveBeenCalledTimes(1)
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
        const mockAccounts = TellerGenerator.generateAccountsWithBalances({
            count: 1,
            institutionId: 'chase_test',
            enrollmentId: 'test-teller-item-workers',
            institutionName: 'Chase Test',
            accountType: 'depository',
            accountSubType: 'checking',
        })
        teller.getAccounts.mockResolvedValueOnce(mockAccounts)

        const mockTransactions = TellerGenerator.generateTransactions(10, mockAccounts[0].id)
        teller.getTransactions.mockResolvedValueOnce(mockTransactions)

        await syncQueue.add('sync-connection', { accountConnectionId: connection.id })

        expect(teller.getAccounts).toHaveBeenCalledTimes(1)
        expect(teller.getTransactions).toHaveBeenCalledTimes(1)

        const item = await prisma.accountConnection.findUniqueOrThrow({
            where: { id: connection.id },
            include: {
                accounts: {
                    include: {
                        balances: {
                            where: TellerGenerator.testDates.prismaWhereFilter,
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

        const intervalDates = Interval.fromDateTimes(
            TellerGenerator.lowerBound,
            TellerGenerator.now
        )
            .splitBy({ day: 1 })
            .map((date: Interval) => date.start.toISODate())

        const startingBalance = Number(mockAccounts[0].balance.available)

        const balances = TellerGenerator.calculateDailyBalances(
            startingBalance,
            mockTransactions,
            intervalDates
        )

        expect(account.transactions).toHaveLength(10)
        expect(account.balances.map((b) => b.balance)).toEqual(balances)
        expect(account.holdings).toHaveLength(0)
        expect(account.valuations).toHaveLength(0)
        expect(account.investmentTransactions).toHaveLength(0)
    })
})
