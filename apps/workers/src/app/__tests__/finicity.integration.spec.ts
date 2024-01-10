import fs from 'fs'
import type { User } from '@prisma/client'
import { FinicityTestData } from '../../../../../tools/test-data'
import { FinicityApi, type FinicityTypes } from '@maybe-finance/finicity-api'
jest.mock('@maybe-finance/finicity-api')
import {
    FinicityETL,
    FinicityService,
    type IAccountConnectionProvider,
} from '@maybe-finance/server/features'
import { createLogger, etl } from '@maybe-finance/server/shared'
import prisma from '../lib/prisma'
import { resetUser } from './helpers/user.test-helper'
import { transports } from 'winston'

const logger = createLogger({ level: 'debug', transports: [new transports.Console()] })
const finicity = jest.mocked(new FinicityApi('APP_KEY', 'PARTNER_ID', 'PARTNER_SECRET'))

/** mock implementation of finicity's pagination logic which as of writing uses 1-based indexing */
function finicityPaginate<T>(data: T[], start = 1, limit = 1_000): T[] {
    const startIdx = Math.max(0, start - 1)
    return data.slice(startIdx, startIdx + limit)
}

describe('Finicity', () => {
    let user: User

    beforeEach(async () => {
        jest.clearAllMocks()

        user = await resetUser(prisma)
    })

    it('syncs connection', async () => {
        finicity.getCustomerAccounts.mockResolvedValue({ accounts: FinicityTestData.accounts })

        finicity.getAccountTransactions.mockImplementation(({ accountId, start, limit }) => {
            const transactions = FinicityTestData.transactions.filter(
                (t) => t.accountId === +accountId
            )

            const page = finicityPaginate(transactions, start, limit)

            return Promise.resolve({
                transactions: page,
                found: transactions.length,
                displaying: page.length,
                moreAvailable: page.length < transactions.length ? 'true' : 'false',
                fromDate: '1588939200',
                toDate: '1651492800',
                sort: 'desc',
            })
        })

        const finicityETL = new FinicityETL(logger, prisma, finicity)

        const service: IAccountConnectionProvider = new FinicityService(
            logger,
            prisma,
            finicity,
            finicityETL,
            '',
            true
        )

        const connection = await prisma.accountConnection.create({
            data: {
                userId: user.id,
                name: 'TEST_FINICITY',
                type: 'finicity',
                finicityInstitutionId: 'REPLACE_THIS',
                finicityInstitutionLoginId: 'REPLACE_THIS',
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

        expect(accounts).toHaveLength(FinicityTestData.accounts.length)

        // eslint-disable-next-line
        const [auto, mortgage, roth, brokerage, loc, credit, savings, checking] =
            FinicityTestData.accounts

        // mortgage
        const mortgageAccount = accounts.find((a) => a.finicityAccountId === mortgage.id)!
        expect(mortgageAccount.transactions).toHaveLength(
            FinicityTestData.transactions.filter((t) => t.accountId === +mortgage.id).length
        )
        expect(mortgageAccount.holdings).toHaveLength(0)
        expect(mortgageAccount.valuations).toHaveLength(0)
        expect(mortgageAccount.investmentTransactions).toHaveLength(0)

        // brokerage
        const brokerageAccount = accounts.find((a) => a.finicityAccountId === brokerage.id)!
        expect(brokerageAccount.transactions).toHaveLength(0)
        expect(brokerageAccount.holdings).toHaveLength(brokerage.position!.length)
        expect(brokerageAccount.valuations).toHaveLength(0)
        expect(brokerageAccount.investmentTransactions).toHaveLength(
            FinicityTestData.transactions.filter((t) => t.accountId === +brokerage.id).length
        )

        // credit
        const creditAccount = accounts.find((a) => a.finicityAccountId === credit.id)!
        expect(creditAccount.transactions).toHaveLength(
            FinicityTestData.transactions.filter((t) => t.accountId === +credit.id).length
        )
        expect(creditAccount.holdings).toHaveLength(0)
        expect(creditAccount.valuations).toHaveLength(0)
        expect(creditAccount.investmentTransactions).toHaveLength(0)

        // savings
        const savingsAccount = accounts.find((a) => a.finicityAccountId === savings.id)!
        expect(savingsAccount.transactions).toHaveLength(
            FinicityTestData.transactions.filter((t) => t.accountId === +savings.id).length
        )
        expect(savingsAccount.holdings).toHaveLength(0)
        expect(savingsAccount.valuations).toHaveLength(0)
        expect(savingsAccount.investmentTransactions).toHaveLength(0)

        // checking
        const checkingAccount = accounts.find((a) => a.finicityAccountId === checking.id)!
        expect(checkingAccount.transactions).toHaveLength(
            FinicityTestData.transactions.filter((t) => t.accountId === +checking.id).length
        )
        expect(checkingAccount.holdings).toHaveLength(0)
        expect(checkingAccount.valuations).toHaveLength(0)
        expect(checkingAccount.investmentTransactions).toHaveLength(0)
    })

    it('syncs Betterment investment account', async () => {
        finicity.getCustomerAccounts.mockResolvedValue({
            accounts: [FinicityTestData.bettermentAccount],
        })

        finicity.getAccountTransactions.mockImplementation(({ accountId, start, limit }) => {
            const transactions = FinicityTestData.bettermentTransactions.filter(
                (t) => t.accountId === +accountId
            )

            const page = finicityPaginate(transactions, start, limit)

            return Promise.resolve({
                transactions: page,
                found: transactions.length,
                displaying: page.length,
                moreAvailable: page.length < transactions.length ? 'true' : 'false',
                fromDate: '1588939200',
                toDate: '1651492800',
                sort: 'desc',
            })
        })

        const finicityETL = new FinicityETL(logger, prisma, finicity)

        const connection = await prisma.accountConnection.create({
            data: {
                userId: user.id,
                name: 'TEST[Betterment]',
                type: 'finicity',
                finicityInstitutionId: FinicityTestData.bettermentAccount.institutionId,
                finicityInstitutionLoginId:
                    FinicityTestData.bettermentAccount.institutionLoginId.toString(),
            },
        })

        await etl(finicityETL, connection)
    })

    it('syncs investment transactions w/o securities', async () => {
        finicity.getCustomerAccounts.mockResolvedValue({
            accounts: [FinicityTestData.accounts.find((a) => a.type === 'investment')!],
        })

        finicity.getAccountTransactions.mockImplementation(({ accountId, start, limit }) => {
            const transactions: FinicityTypes.Transaction[] = [
                {
                    id: 1,
                    amount: 123,
                    accountId: +accountId,
                    customerId: 123,
                    status: 'active',
                    description: 'VANGUARD INST INDEX',
                    memo: 'Contributions',
                    type: 'Contributions',
                    unitQuantity: 8.283,
                    postedDate: 1674043200,
                    transactionDate: 1674043200,
                    createdDate: 1674707388,
                    tradeDate: 1674025200,
                    settlementDate: 1674043200,
                    investmentTransactionType: 'contribution',
                },
                {
                    id: 2,
                    amount: -3.21,
                    accountId: +accountId,
                    customerId: 123,
                    status: 'active',
                    description: 'VANGUARD TARGET 2045',
                    memo: 'RECORDKEEPING FEE',
                    type: 'RECORDKEEPING FEE',
                    unitQuantity: 0.014,
                    postedDate: 1672747200,
                    transactionDate: 1672747200,
                    createdDate: 1674707388,
                    tradeDate: 1672729200,
                    settlementDate: 1672747200,
                    investmentTransactionType: 'fee',
                },
                {
                    id: 3,
                    amount: -1.23,
                    accountId: +accountId,
                    customerId: 123,
                    status: 'active',
                    description: 'VANGUARD INST INDEX',
                    memo: 'Realized Gain/Loss',
                    type: 'Realized Gain/Loss',
                    unitQuantity: 0e-8,
                    postedDate: 1672747200,
                    transactionDate: 1672747200,
                    createdDate: 1674707388,
                    tradeDate: 1672729200,
                    settlementDate: 1672747200,
                    investmentTransactionType: 'other',
                },
            ]

            const page = finicityPaginate(transactions, start, limit)

            return Promise.resolve({
                transactions: page,
                found: transactions.length,
                displaying: page.length,
                moreAvailable: page.length < transactions.length ? 'true' : 'false',
                fromDate: '1588939200',
                toDate: '1651492800',
                sort: 'desc',
            })
        })

        const finicityETL = new FinicityETL(logger, prisma, finicity)

        const connection = await prisma.accountConnection.create({
            data: {
                userId: user.id,
                name: 'TEST[Betterment]',
                type: 'finicity',
                finicityInstitutionId: FinicityTestData.bettermentAccount.institutionId,
                finicityInstitutionLoginId:
                    FinicityTestData.bettermentAccount.institutionLoginId.toString(),
            },
        })

        await etl(finicityETL, connection)

        const accounts = await prisma.account.findMany({
            where: {
                accountConnectionId: connection.id,
            },
            include: {
                holdings: true,
                transactions: true,
                investmentTransactions: true,
            },
        })
        expect(accounts).toHaveLength(1)

        const account = accounts[0]
        expect(account.holdings).toHaveLength(0)
        expect(account.transactions).toHaveLength(0)
        expect(account.investmentTransactions).toHaveLength(3)
    })

    /**
     * This test is for debugging w/ real data locally
     */
    it.skip('debug', async () => {
        const data = (name: string) =>
            JSON.parse(
                fs.readFileSync(`${process.env.NX_TEST_DATA_FOLDER}/finicity/${name}.json`, 'utf-8')
            )

        finicity.getCustomerAccounts.mockResolvedValue(data('accounts'))
        finicity.getAccountTransactions.mockResolvedValue(data('transactions'))

        const finicityETL = new FinicityETL(logger, prisma, finicity)

        const connection = await prisma.accountConnection.create({
            data: {
                userId: user.id,
                name: 'TEST[DEBUG]',
                type: 'finicity',
                finicityInstitutionId: '123',
                finicityInstitutionLoginId: '123',
            },
        })

        await etl(finicityETL, connection)
    })
})
