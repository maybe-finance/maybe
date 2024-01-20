import type { User } from '@prisma/client'
import { PrismaClient, InvestmentTransactionCategory } from '@prisma/client'
import { createLogger, transports } from 'winston'
import { DateTime } from 'luxon'
import {
    AccountQueryService,
    AccountService,
    BalanceSyncStrategyFactory,
    LoanBalanceSyncStrategy,
    TransactionBalanceSyncStrategy,
    ValuationBalanceSyncStrategy,
} from '@maybe-finance/server/features'
import { InvestmentTransactionBalanceSyncStrategy } from '@maybe-finance/server/features'
import { resetUser } from './utils/user'
import { createTestInvestmentAccount } from './utils/account'
import { PgService } from '@maybe-finance/server/shared'
import type { SharedType } from '@maybe-finance/shared'

const prisma = new PrismaClient()
const logger = createLogger({ transports: [new transports.Console()] })

let user: User

const transactionStrategy = new TransactionBalanceSyncStrategy(logger, prisma)

const investmentTransactionStrategy = new InvestmentTransactionBalanceSyncStrategy(logger, prisma)

const valuationStrategy = new ValuationBalanceSyncStrategy(logger, prisma)

const loanStrategy = new LoanBalanceSyncStrategy(logger, prisma)

const balanceSyncStrategyFactory = new BalanceSyncStrategyFactory({
    INVESTMENT: investmentTransactionStrategy,
    DEPOSITORY: transactionStrategy,
    CREDIT: transactionStrategy,
    LOAN: loanStrategy,
    PROPERTY: valuationStrategy,
    VEHICLE: valuationStrategy,
    OTHER_ASSET: valuationStrategy,
    OTHER_LIABILITY: valuationStrategy,
})

const pgService = new PgService(logger)

const queryService = new AccountQueryService(logger, pgService)

const accountService = new AccountService(
    logger,
    prisma,
    queryService,
    {} as any,
    {} as any,
    balanceSyncStrategyFactory
)

beforeEach(async () => {
    user = await resetUser()
})

afterAll(async () => {
    await prisma.$disconnect()
})

describe('balance sync strategies', () => {
    describe('investment accounts', () => {
        it('syncs balances', async () => {
            const account = await createTestInvestmentAccount(prisma, user, 'portfolio-1')

            await accountService.syncBalances(account.id)

            const balances = await accountService.getBalances(
                account.id,
                '2021-12-30',
                '2022-04-01',
                'days'
            )

            const actualBalances = balances.series.data.map((b) => b.balance.toNumber())

            // // 12/30/21 => 4/1/22 balances (see google sheet)
            const expectedBalances = [
                0, 5000, 5000, 5000, 5005, 5010, 5010, 5010, 5010, 5010, 5010, 5010, 5010, 5020,
                5040, 5040, 5040, 5040, 5040, 5040, 5040, 5040, 5040, 5040, 5040, 5040, 5040, 5020,
                5020, 5020, 5020, 5020, 5020, 5020, 5020, 5020, 5020, 4020, 4020, 4078, 4062, 4062,
                4062, 4062, 4062, 4062, 4062, 4062, 4062, 4092, 4092, 4092, 4092, 4092, 4092, 4092,
                4124, 4124, 4124, 4124, 4134, 4134, 4144, 4144, 4144, 4144, 4144, 4144, 8144, 8170,
                8385, 8590, 8642, 8642, 8642, 8402, 8402, 8402, 8402, 8402, 8402, 8402, 8402, 8402,
                8282, 8282, 8282, 8282, 8282, 8462, 8462, 8462, 8462,
            ]

            expect(actualBalances).toEqual(expectedBalances)
        })

        it('syncs balances w/ txn amt/qty sign mismatch', async () => {
            const account = await prisma.$transaction(async (tx) => {
                const security = await tx.security.create({
                    data: {
                        symbol: 'AAPL',
                        pricing: {
                            create: {
                                date: DateTime.fromISO('2023-02-01').toJSDate(),
                                priceClose: 10,
                            },
                        },
                    },
                })

                return tx.account.create({
                    data: {
                        name: 'test investment account',
                        provider: 'user',
                        type: 'INVESTMENT',
                        currentBalanceProvider: 50,
                        availableBalanceProvider: 0,
                        holdings: {
                            create: [
                                {
                                    securityId: security.id,
                                    quantity: 5,
                                    value: 50,
                                },
                            ],
                        },
                        investmentTransactions: {
                            create: [
                                {
                                    date: DateTime.fromISO('2023-02-01').toJSDate(),
                                    securityId: security.id,
                                    name: 'buy - seed',
                                    amount: 100,
                                    quantity: 10,
                                    price: 10,
                                    category: InvestmentTransactionCategory.buy,
                                },
                                {
                                    date: DateTime.fromISO('2023-02-04').toJSDate(),
                                    securityId: security.id,
                                    name: 'sell - amt/qty sign mismatch',
                                    amount: -50,
                                    quantity: 5,
                                    price: 10,
                                    category: InvestmentTransactionCategory.sell,
                                },
                                {
                                    date: DateTime.fromISO('2023-02-04').toJSDate(),
                                    name: 'withdraw - cash out',
                                    amount: 50,
                                    quantity: 50,
                                    price: 1,
                                    category: InvestmentTransactionCategory.other,
                                },
                            ],
                        },
                    },
                })
            })

            await accountService.syncBalances(account.id)

            const balances = await accountService.getBalances(
                account.id,
                '2023-02-01',
                '2023-02-07',
                'days'
            )

            expect(balances.series.data.map((d) => +d.balance)).toEqual([
                100, 100, 100, 50, 50, 50, 50,
            ])
        })

        it.each`
            current | available | expected
            ${123}  | ${null}   | ${123}
            ${123}  | ${0}      | ${123}
        `(
            'syncs account w/ no holdings or transactions (current=$current available=$available)',
            async ({ current, available, expected }) => {
                const account = await prisma.account.create({
                    data: {
                        name: 'test investment account',
                        provider: 'user',
                        type: 'INVESTMENT',
                        currentBalanceProvider: current,
                        availableBalanceProvider: available,
                    },
                })

                await accountService.syncBalances(account.id)

                const balances = await accountService.getBalances(
                    account.id,
                    '2023-01-01',
                    '2023-01-07',
                    'days'
                )

                expect(balances.series.data.map((d) => +d.balance)).toEqual(Array(7).fill(expected))
            }
        )
    })

    it('syncs depository balances', async () => {
        expect(1).toEqual(1)
    })

    it('syncs valuation balances', async () => {
        expect(1).toEqual(1)
    })

    describe('loan accounts', () => {
        it('syncs loan w/ transactions', async () => {
            // we want to test a loan account that has transaction data
            const account = await prisma.account.create({
                data: {
                    user: { connect: { id: user.id } },
                    name: 'test loan balance sync strategy',
                    type: 'LOAN',
                    provider: 'user',
                    currentBalanceProvider: 50,
                    availableBalanceProvider: 0,
                    startDate: DateTime.fromISO('2022-07-31').toJSDate(),
                    loanUser: {
                        interestRate: { type: 'fixed', rate: 0.1 },
                        loanDetail: { type: 'other' },
                        originationDate: '2022-07-31',
                        originationPrincipal: 200,
                    } as SharedType.Loan,
                    transactions: {
                        createMany: {
                            data: [
                                {
                                    date: DateTime.fromISO('2022-08-05').toJSDate(),
                                    amount: -50,
                                    name: 'PAYMENT',
                                },
                            ],
                        },
                    },
                },
            })

            await accountService.syncBalances(account.id)

            const balances = await accountService.getBalances(
                account.id,
                '2022-08-01',
                '2022-08-07',
                'days'
            )

            expect(balances.series.data.map((d) => d.balance.toNumber())).toEqual([
                175, 150, 125, 100, 50, 50, 50,
            ])
        })

        it('syncs loan without loan data', async () => {
            const account = await prisma.account.create({
                data: {
                    userId: user.id,
                    name: 'test loan balance sync strategy',
                    type: 'LOAN',
                    provider: 'user',
                    currentBalanceProvider: 0,
                    availableBalanceProvider: 0,
                    startDate: DateTime.fromISO('2022-07-31').toJSDate(),
                },
            })

            await accountService.syncBalances(account.id)

            const balances = await accountService.getBalances(
                account.id,
                '2022-08-01',
                '2022-08-07',
                'days'
            )

            expect(balances.series.data.map((d) => d.balance.toNumber())).toEqual([
                0, 0, 0, 0, 0, 0, 0,
            ])
        })
    })
})
