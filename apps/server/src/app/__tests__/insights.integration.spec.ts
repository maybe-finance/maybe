import type { User } from '@prisma/client'
import { Prisma, PrismaClient } from '@prisma/client'
import { createLogger, transports } from 'winston'
import { DateTime } from 'luxon'
import type {
    IBalanceSyncStrategyFactory,
    IInsightService,
    ITransactionService,
} from '@maybe-finance/server/features'
import { InvestmentTransactionBalanceSyncStrategy } from '@maybe-finance/server/features'
import { InsightService, TransactionService } from '@maybe-finance/server/features'
import { resetUser } from './utils/user'
import { createTestInvestmentAccount } from './utils/account'

const prisma = new PrismaClient()

const date = (s: string) => DateTime.fromISO(s, { zone: 'utc' }).toJSDate()

let user: User

beforeEach(async () => {
    // Clears old user and data, creates new user
    user = await resetUser()
})

afterAll(async () => {
    await prisma.$disconnect()
})

describe('insight service', () => {
    let transactionService: ITransactionService
    let insightService: IInsightService
    let balanceSyncStrategyFactory: IBalanceSyncStrategyFactory

    beforeEach(async () => {
        const logger = createLogger({ transports: [new transports.Console()] })

        transactionService = new TransactionService(logger, prisma)
        insightService = new InsightService(logger, prisma)
        balanceSyncStrategyFactory = {
            for: () => new InvestmentTransactionBalanceSyncStrategy(logger, prisma),
        }

        await prisma.user.update({
            where: { id: user.id },
            data: {
                accounts: { deleteMany: {} },
            },
        })
    })

    describe('user insights', () => {
        it('calculates transaction summary correctly', async () => {
            // create accounts
            const [checking, savings, credit, loan] = await Promise.all([
                prisma.account.create({
                    data: {
                        userId: user.id,
                        name: 'Checking Account',
                        type: 'DEPOSITORY',
                        provider: 'user',
                        startDate: date('2022-07-01'),
                        currentBalanceProvider: 1_000,
                    },
                }),
                prisma.account.create({
                    data: {
                        userId: user.id,
                        name: 'Savings Account',
                        type: 'DEPOSITORY',
                        provider: 'user',
                        startDate: date('2022-07-01'),
                        currentBalanceProvider: 2_000,
                    },
                }),
                prisma.account.create({
                    data: {
                        userId: user.id,
                        name: 'Credit Card',
                        type: 'CREDIT',
                        provider: 'user',
                        startDate: date('2022-07-01'),
                        currentBalanceProvider: 10,
                    },
                }),
                prisma.account.create({
                    data: {
                        userId: user.id,
                        name: 'Mortgage',
                        type: 'LOAN',
                        provider: 'user',
                        startDate: date('2022-07-01'),
                        currentBalanceProvider: 100_000,
                    },
                }),
            ])

            // create transactions
            await prisma.transaction.createMany({
                data: [
                    {
                        accountId: checking.id,
                        amount: 1_000,
                        name: 'Mortgage Payment',
                        date: date('2022-07-01'),
                    },
                    {
                        accountId: loan.id,
                        amount: -1_000,
                        name: 'Mortgage Payment from Checking',
                        date: date('2022-07-02'),
                    },
                    {
                        accountId: checking.id,
                        amount: -100,
                        name: 'Payroll Direct Deposit',
                        date: date('2022-07-04'),
                    },
                    {
                        accountId: savings.id,
                        amount: -100,
                        name: 'Payroll Direct Deposit',
                        date: date('2022-07-04'),
                    },
                    {
                        accountId: checking.id,
                        amount: 100,
                        name: 'Transfer to Savings',
                        date: date('2022-07-04'),
                    },
                    {
                        accountId: savings.id,
                        amount: -100,
                        name: 'Transfer from Checking',
                        date: date('2022-07-05'),
                    },
                    {
                        accountId: credit.id,
                        amount: 100,
                        name: 'Purchase w/ Credit Card',
                        date: date('2022-07-04'),
                    },
                    {
                        accountId: credit.id,
                        amount: 50,
                        name: 'Purchase w/ Credit Card',
                        date: date('2022-07-05'),
                    },
                    {
                        accountId: checking.id,
                        amount: 100,
                        name: 'Payment to Credit Card',
                        date: date('2022-07-07'),
                    },
                    {
                        accountId: credit.id,
                        amount: -100,
                        name: 'Payment from Checking',
                        date: date('2022-07-07'),
                    },
                    {
                        accountId: credit.id,
                        amount: 1_000,
                        name: 'Purchase w/ Credit Card',
                        date: date('2022-07-09'),
                        excluded: true,
                    },
                ],
            })

            const { transactionSummary } = await insightService.getUserInsights({
                userId: user.id,
                now: DateTime.fromISO('2022-08-02'),
            })

            expect(transactionSummary.income).toEqual(new Prisma.Decimal(300))
            expect(transactionSummary.expenses).toEqual(new Prisma.Decimal(1350))
            expect(transactionSummary.payments).toEqual(new Prisma.Decimal(1_000))

            await transactionService.markTransfers(user.id)
            const { transactionSummary: summary2 } = await insightService.getUserInsights({
                userId: user.id,
                now: DateTime.fromISO('2022-08-02'),
            })

            expect(summary2.income).toEqual(new Prisma.Decimal(100))
            expect(summary2.expenses).toEqual(new Prisma.Decimal(150))
            expect(summary2.payments).toEqual(new Prisma.Decimal(1_000))
        })
    })

    describe('account insights', () => {
        it('calculates PnL, cost basis, and holdings breakdown', async () => {
            const account = await prisma.account.create({
                data: {
                    userId: user.id,
                    name: 'Investment Account',
                    type: 'INVESTMENT',
                    provider: 'user',
                    startDate: date('2022-07-01'),
                    currentBalanceProvider: 500,
                    holdings: {
                        create: [
                            {
                                security: { create: { symbol: 'AAPL', plaidType: 'equity' } },
                                quantity: 1,
                                costBasisUser: 100,
                                value: 200,
                            },
                            {
                                security: { create: { symbol: 'NFLX', plaidType: 'equity' } },
                                quantity: 10,
                                costBasisUser: 200,
                                value: 300,
                            },
                            {
                                security: { create: { symbol: 'SHOP', plaidType: 'equity' } },
                                quantity: 2,
                                costBasisUser: 100,
                                value: 50,
                            },
                        ],
                    },
                },
            })

            const { portfolio } = await insightService.getAccountInsights({
                accountId: account.id,
            })

            expect(portfolio).toBeDefined()
            expect(portfolio!.pnl).toMatchObject({
                amount: new Prisma.Decimal(150),
                percentage: new Prisma.Decimal(0.375),
                direction: 'up',
            })
            expect(portfolio!.costBasis).toEqual(new Prisma.Decimal(400))
            expect(portfolio!.holdingBreakdown).toHaveLength(1)
            expect(portfolio!.holdingBreakdown[0]).toMatchObject({
                asset_class: 'stocks',
                amount: new Prisma.Decimal(550),
                percentage: new Prisma.Decimal(1),
            })
        })

        it('calculates returns on basic sample portfolio', async () => {
            const account = await createTestInvestmentAccount(prisma, user, 'portfolio-1')

            await balanceSyncStrategyFactory.for(account).syncAccountBalances(account)

            const { portfolio } = await insightService.getAccountInsights({
                accountId: account.id,
                now: DateTime.fromISO('2022-03-31', { zone: 'utc' }),
            })

            expect(portfolio).toBeDefined()
            expect(portfolio!.return.ytd).toBeDefined()
            expect(portfolio!.return.ytd!.amount).toEqual(new Prisma.Decimal(462))
            expect(portfolio!.return.ytd!.percentage).toEqual(new Prisma.Decimal(0.0851))
            expect(portfolio!.return.ytd!.direction).toBe('up')
        })
    })

    describe('holding insights', () => {
        it('calculates holdings insights', async () => {
            const account = await prisma.account.create({
                data: {
                    userId: user.id,
                    name: 'Investment Account',
                    type: 'INVESTMENT',
                    provider: 'user',
                    startDate: date('2022-07-01'),
                    currentBalanceProvider: 7000,
                    availableBalanceProvider: 0,
                    holdings: {
                        create: [
                            {
                                security: { create: { name: 'Apple', symbol: 'AAPL_TEST' } },
                                quantity: 50,
                                costBasisUser: 100,
                                value: 5000,
                            },
                            {
                                security: { create: { name: 'Netflix', symbol: 'NFLX_TEST' } },
                                quantity: 10,
                                costBasisUser: 200,
                                value: 2000,
                            },
                        ],
                    },
                },
                include: { holdings: { include: { security: true } } },
            })

            const AAPL = account.holdings.find((h) => h.security.symbol === 'AAPL_TEST')!
            const NFLX = account.holdings.find((h) => h.security.symbol === 'NFLX_TEST')!

            await prisma.investmentTransaction.createMany({
                data: [
                    {
                        accountId: account.id,
                        securityId: AAPL.securityId,
                        date: date('2022-06-01'),
                        name: 'Buy AAPL',
                        amount: 50 * 100,
                        quantity: 50,
                        price: 100,
                        plaidType: 'buy',
                        plaidSubtype: 'buy',
                    },
                    {
                        accountId: account.id,
                        securityId: NFLX.securityId,
                        date: date('2022-06-02'),
                        name: 'Buy NFLX',
                        amount: 10 * 200,
                        quantity: 10,
                        price: 200,
                        plaidType: 'buy',
                        plaidSubtype: 'buy',
                    },
                    {
                        accountId: account.id,
                        securityId: AAPL.securityId,
                        date: date('2022-06-20'),
                        name: 'AAPL Dividend',
                        amount: -20.22,
                        quantity: 0,
                        price: 0,
                        plaidType: 'cash',
                        plaidSubtype: 'dividend',
                    },
                    {
                        accountId: account.id,
                        securityId: AAPL.securityId,
                        date: date('2022-06-28'),
                        name: 'AAPL Dividend',
                        amount: -22.85,
                        quantity: 0,
                        price: 0,
                        plaidType: 'cash',
                        plaidSubtype: 'dividend',
                    },
                ],
            })

            const { allocation, dividends } = await insightService.getHoldingInsights({
                holding: AAPL,
            })

            //clean up
            await prisma.security.deleteMany({
                where: { symbol: { in: ['AAPL_TEST', 'NFLX_TEST'] } },
            })
            await prisma.account.delete({ where: { id: account.id } })

            expect(allocation?.toNumber()).toEqual(5000 / 7000)
            expect(dividends?.toNumber()).toEqual(-20.22 + -22.85)
        })
    })

    describe('plan insights', () => {
        it('calculates correctly', async () => {
            // update user income/expenses
            await prisma.user.update({
                where: { id: user.id },
                data: {
                    monthlyIncomeUser: 10_000,
                    monthlyExpensesUser: 5_000,
                    monthlyDebtUser: 0,
                },
            })

            // create accounts
            await prisma.account.createMany({
                data: [
                    {
                        userId: user.id,
                        name: 'Checking Account',
                        type: 'DEPOSITORY',
                        provider: 'user',
                        startDate: date('2022-01-01'),
                        currentBalanceProvider: 10_000,
                    },
                    {
                        userId: user.id,
                        name: 'Credit Card',
                        type: 'CREDIT',
                        provider: 'user',
                        startDate: date('2022-01-01'),
                        currentBalanceProvider: 1_000,
                    },
                    {
                        userId: user.id,
                        name: 'Mortgage',
                        type: 'LOAN',
                        provider: 'user',
                        startDate: date('2022-01-01'),
                        currentBalanceProvider: 800_000,
                    },
                    {
                        userId: user.id,
                        name: 'House',
                        type: 'PROPERTY',
                        provider: 'user',
                        startDate: date('2022-01-01'),
                        currentBalanceProvider: 1_000_000,
                    },
                ],
            })

            const { projectionAssetBreakdown, projectionLiabilityBreakdown, income, expenses } =
                await insightService.getPlanInsights({
                    userId: user.id,
                    now: DateTime.fromISO('2022-01-01', { zone: 'utc' }),
                })

            expect(income).toEqual(new Prisma.Decimal(120_000))
            expect(expenses).toEqual(new Prisma.Decimal(60_000))

            expect(projectionAssetBreakdown).toContainEqual({
                type: 'cash',
                amount: new Prisma.Decimal(10_000),
            })
            expect(projectionAssetBreakdown).toContainEqual({
                type: 'property',
                amount: new Prisma.Decimal(1_000_000),
            })

            expect(projectionLiabilityBreakdown).toContainEqual({
                type: 'credit',
                amount: new Prisma.Decimal(1_000),
            })
            expect(projectionLiabilityBreakdown).toContainEqual({
                type: 'loan',
                amount: new Prisma.Decimal(800_000),
            })
        })
    })
})
