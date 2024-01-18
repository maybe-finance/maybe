import type { User } from '@prisma/client'
import { TellerGenerator } from '../../../../../tools/generators'
import { TellerApi } from '@maybe-finance/teller-api'
jest.mock('@maybe-finance/teller-api')
import {
    TellerETL,
    TellerService,
    type IAccountConnectionProvider,
} from '@maybe-finance/server/features'
import { createLogger } from '@maybe-finance/server/shared'
import prisma from '../lib/prisma'
import { resetUser } from './helpers/user.test-helper'
import { transports } from 'winston'
import { cryptoService } from '../lib/di'

const logger = createLogger({ level: 'debug', transports: [new transports.Console()] })
const teller = jest.mocked(new TellerApi())
const tellerETL = new TellerETL(logger, prisma, teller, cryptoService)
const service: IAccountConnectionProvider = new TellerService(
    logger,
    prisma,
    teller,
    tellerETL,
    cryptoService,
    'TELLER_WEBHOOK_URL',
    true
)

afterAll(async () => {
    await prisma.$disconnect()
})

describe('Teller', () => {
    let user: User

    beforeEach(async () => {
        jest.clearAllMocks()

        user = await resetUser(prisma)
    })

    it('syncs connection', async () => {
        const tellerConnection = TellerGenerator.generateConnection()
        const tellerAccounts = tellerConnection.accountsWithBalances
        const tellerTransactions = tellerConnection.transactions

        teller.getAccounts.mockResolvedValue(tellerAccounts)

        teller.getTransactions.mockImplementation(async ({ accountId }) => {
            return Promise.resolve(tellerTransactions.filter((t) => t.account_id === accountId))
        })

        const connection = await prisma.accountConnection.create({
            data: {
                userId: user.id,
                name: 'TEST_TELLER',
                type: 'teller',
                tellerEnrollmentId: tellerConnection.enrollment.enrollment.id,
                tellerInstitutionId: tellerConnection.enrollment.institutionId,
                tellerAccessToken: cryptoService.encrypt(tellerConnection.enrollment.accessToken),
            },
        })

        await service.sync(connection)

        const { accounts } = await prisma.accountConnection.findUniqueOrThrow({
            where: {
                id: connection.id,
            },
            include: {
                accounts: {
                    include: {
                        transactions: true,
                        investmentTransactions: true,
                        holdings: true,
                        valuations: true,
                    },
                },
            },
        })

        // all accounts
        expect(accounts).toHaveLength(tellerConnection.accounts.length)
        for (const account of accounts) {
            expect(account.transactions).toHaveLength(
                tellerTransactions.filter((t) => t.account_id === account.tellerAccountId).length
            )
        }

        // credit accounts
        const creditAccounts = tellerAccounts.filter((a) => a.type === 'credit')
        expect(accounts.filter((a) => a.type === 'CREDIT')).toHaveLength(creditAccounts.length)
        for (const creditAccount of creditAccounts) {
            const account = accounts.find((a) => a.tellerAccountId === creditAccount.id)!
            expect(account.transactions).toHaveLength(
                tellerTransactions.filter((t) => t.account_id === account.tellerAccountId).length
            )
            expect(account.holdings).toHaveLength(0)
            expect(account.valuations).toHaveLength(0)
            expect(account.investmentTransactions).toHaveLength(0)
        }

        // depository accounts
        const depositoryAccounts = tellerAccounts.filter((a) => a.type === 'depository')
        expect(accounts.filter((a) => a.type === 'DEPOSITORY')).toHaveLength(
            depositoryAccounts.length
        )
        for (const depositoryAccount of depositoryAccounts) {
            const account = accounts.find((a) => a.tellerAccountId === depositoryAccount.id)!
            expect(account.transactions).toHaveLength(
                tellerTransactions.filter((t) => t.account_id === account.tellerAccountId).length
            )
            expect(account.holdings).toHaveLength(0)
            expect(account.valuations).toHaveLength(0)
            expect(account.investmentTransactions).toHaveLength(0)
        }
    })
})
