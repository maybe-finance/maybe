import fs from 'fs'
import type { User } from '@prisma/client'
import type { IAccountConnectionProvider } from '@maybe-finance/server/features'
import type { IMarketDataService } from '@maybe-finance/server/shared'
import { PlaidService, PlaidETL } from '@maybe-finance/server/features'
import { createLogger, transports } from 'winston'
import { PlaidApi } from 'plaid'
jest.mock('plaid')
import { CryptoService, etl } from '@maybe-finance/server/shared'
import { TestUtil } from '@maybe-finance/shared'
import prisma from '../lib/prisma'
import { resetUser } from './helpers/user.test-helper'
import { uniqBy } from 'lodash'
import { PlaidTestData } from '../../../../../tools/test-data'

const logger = createLogger({ level: 'debug', transports: [new transports.Console()] })
const crypto = new CryptoService('SECRET')
const marketDataService: Pick<IMarketDataService, 'getOptionDetails'> = {
    getOptionDetails: async () => ({ sharesPerContract: 100 }),
}

const plaid = jest.mocked(new PlaidApi())
const plaidETL = new PlaidETL(logger, prisma, plaid, crypto, marketDataService)
const service: IAccountConnectionProvider = new PlaidService(
    logger,
    prisma,
    plaid,
    plaidETL,
    crypto,
    'PLAID_WEBHOOK_URL',
    'CLIENT_URL'
)

// When debugging, we don't want the tests to time out
if (process.env.IS_VSCODE_DEBUG === 'true') {
    jest.setTimeout(100000)
}

describe('Plaid', () => {
    let user: User

    beforeEach(async () => {
        jest.clearAllMocks()

        user = await resetUser(prisma)
    })

    it('syncs connection', async () => {
        plaid.accountsGet.mockResolvedValue(
            TestUtil.axiosSuccess({
                accounts: [
                    PlaidTestData.checkingAccount,
                    PlaidTestData.creditAccount,
                    PlaidTestData.brokerageAccount,
                ],
                item: PlaidTestData.item,
                request_id: '',
            })
        )

        plaid.transactionsGet.mockResolvedValue(
            TestUtil.axiosSuccess({
                accounts: [PlaidTestData.checkingAccount, PlaidTestData.creditAccount],
                transactions: [
                    ...PlaidTestData.checkingTransactions,
                    ...PlaidTestData.creditTransactions,
                ],
                total_transactions:
                    PlaidTestData.checkingTransactions.length +
                    PlaidTestData.creditTransactions.length,
                item: PlaidTestData.item,
                request_id: '',
            })
        )

        plaid.investmentsTransactionsGet.mockResolvedValue(
            TestUtil.axiosSuccess({
                accounts: [PlaidTestData.brokerageAccount],
                investment_transactions: PlaidTestData.investmentTransactions,
                holdings: PlaidTestData.holdings,
                securities: PlaidTestData.securities,
                total_investment_transactions: PlaidTestData.investmentTransactions.length,
                item: PlaidTestData.item,
                request_id: '',
            })
        )

        plaid.investmentsHoldingsGet.mockResolvedValue(
            TestUtil.axiosSuccess({
                accounts: [PlaidTestData.brokerageAccount],
                holdings: PlaidTestData.holdings,
                securities: PlaidTestData.securities,
                item: PlaidTestData.item,
                request_id: '',
            })
        )

        plaid.liabilitiesGet.mockResolvedValue(
            TestUtil.axiosSuccess({
                accounts: [PlaidTestData.creditAccount],
                liabilities: {
                    credit: [PlaidTestData.creditCardLiability],
                    mortgage: null,
                    student: null,
                },
                item: PlaidTestData.item,
                request_id: '',
            })
        )

        const connection = await prisma.accountConnection.create({
            data: {
                userId: user.id,
                name: 'TEST_PLAID',
                type: 'plaid',
                plaidAccessToken: 'abcdef',
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

        expect(accounts).toHaveLength(3)

        // checking
        const checkingAccount = accounts.find(
            (a) => a.plaidAccountId === PlaidTestData.checkingAccount.account_id
        )!
        expect(checkingAccount.transactions).toHaveLength(PlaidTestData.checkingTransactions.length)
        expect(checkingAccount.holdings).toHaveLength(0)
        expect(checkingAccount.valuations).toHaveLength(0)
        expect(checkingAccount.investmentTransactions).toHaveLength(0)

        // credit
        const creditAccount = accounts.find(
            (a) => a.plaidAccountId === PlaidTestData.creditAccount.account_id
        )!
        expect(creditAccount.transactions).toHaveLength(PlaidTestData.creditTransactions.length)
        expect(creditAccount.holdings).toHaveLength(0)
        expect(creditAccount.valuations).toHaveLength(0)
        expect(creditAccount.investmentTransactions).toHaveLength(0)
        expect(creditAccount.plaidLiability).toMatchObject({})

        // brokerage
        const brokerageAccount = accounts.find(
            (a) => a.plaidAccountId === PlaidTestData.brokerageAccount.account_id
        )!
        expect(brokerageAccount.transactions).toHaveLength(0)
        expect(brokerageAccount.holdings).toHaveLength(PlaidTestData.holdings.length)
        expect(brokerageAccount.valuations).toHaveLength(0)
        expect(brokerageAccount.investmentTransactions).toHaveLength(
            PlaidTestData.investmentTransactions.length
        )
    })

    /**
     * Example input: Wealthfront account with multiple 529 Savings Plans
     *
     * Cash accounts have same account and security, but are individual holdings with different qty
     *
     * * 529 Savings Plan 1
     *    * Cash Account 1
     *    * Cash Account 2
     * * 529 Savings Plan 2
     *    * Cash Account 1
     *    * Cash Account 2
     */
    it('syncs Wealthfront account with duplicate cash holdings', async () => {
        plaid.accountsGet.mockResolvedValue(PlaidTestData.Wealthfront1.accountsGetResponse)
        plaid.transactionsGet.mockResolvedValue(PlaidTestData.Wealthfront1.transactionsGetResponse)
        plaid.investmentsTransactionsGet.mockResolvedValue(
            PlaidTestData.Wealthfront1.investmentTransactionsGetResponse
        )
        plaid.investmentsHoldingsGet.mockResolvedValue(
            PlaidTestData.Wealthfront1.holdingsGetResponse
        )
        plaid.liabilitiesGet.mockRejectedValue(PlaidTestData.Wealthfront1.liabilitiesGetResponse)

        const connection = await prisma.accountConnection.create({
            data: {
                userId: user.id,
                name: 'TEST_PLAID',
                type: 'plaid',
                plaidAccessToken: 'abcdef',
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
                        balances: true,
                        transactions: true,
                        holdings: true,
                        valuations: true,
                        investmentTransactions: true,
                    },
                    orderBy: { plaidAccountId: 'asc' },
                },
            },
        })

        expect(accounts).toHaveLength(4)

        const [_529Savings1, _529Savings2, investmentAccount, _529Savings3] = accounts

        // All 529 accounts should have multiple cash holdings
        expect(_529Savings1.holdings).toHaveLength(7)
        expect(_529Savings2.holdings).toHaveLength(7)
        expect(_529Savings3.holdings).toHaveLength(7)

        // 529 accounts have multiple holdings, but all the same security
        expect(uniqBy(_529Savings1.holdings, (h) => h.securityId)).toHaveLength(1)
        expect(uniqBy(_529Savings2.holdings, (h) => h.securityId)).toHaveLength(1)
        expect(uniqBy(_529Savings3.holdings, (h) => h.securityId)).toHaveLength(1)

        // Investment account has no duplicate securities
        expect(investmentAccount.holdings).toHaveLength(8)
        expect(uniqBy(investmentAccount.holdings, (h) => h.securityId)).toHaveLength(8)
    })

    /**
     * This test is for debugging w/ real data locally
     */
    it.skip('debug', async () => {
        const data = (name: string) =>
            JSON.parse(
                fs.readFileSync(`${process.env.NX_TEST_DATA_FOLDER}/plaid/${name}.json`, 'utf-8')
            )

        plaid.accountsGet.mockResolvedValue(TestUtil.axiosSuccess(data('accounts')))
        plaid.transactionsGet.mockResolvedValue(TestUtil.axiosSuccess(data('transactions')))
        plaid.investmentsTransactionsGet.mockResolvedValue(
            TestUtil.axiosSuccess(data('investment-transactions'))
        )
        plaid.investmentsHoldingsGet.mockResolvedValue(TestUtil.axiosSuccess(data('holdings')))
        plaid.liabilitiesGet.mockRejectedValue(
            TestUtil.axios400Error({
                display_message: null,
                documentation_url: 'https://plaid.com/docs/?ref=error#item-errors',
                error_code: 'PRODUCTS_NOT_SUPPORTED',
                error_message:
                    'the following products are not supported by this institution: ["liabilities"]',
                error_type: 'ITEM_ERROR',
                request_id: 'abc',
                suggested_action: null,
            })
        )

        const connection = await prisma.accountConnection.create({
            data: {
                userId: user.id,
                name: 'TEST[DEBUG]',
                type: 'plaid',
                plaidAccessToken: 'abcdef',
            },
        })

        await etl(plaidETL, connection)
    })
})
