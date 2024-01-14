import type { AccountCategory, AccountProvider, AccountType, User } from '@prisma/client'
import { PrismaClient, Prisma } from '@prisma/client'
import { createLogger, transports } from 'winston'
import { DateTime } from 'luxon'
import { PgService } from '@maybe-finance/server/shared'
import { AccountQueryService, UserService } from '@maybe-finance/server/features'
import { resetUser } from './utils/user'
jest.mock('plaid')
jest.mock('auth0')

const prisma = new PrismaClient()

const date = (s: string) => DateTime.fromISO(s, { zone: 'utc' }).toJSDate()

let user: User

beforeEach(async () => {
    user = await resetUser()
})

afterAll(async () => {
    await prisma.$disconnect()
})

describe('user net worth', () => {
    let userService: UserService

    beforeEach(async () => {
        const logger = createLogger({ transports: [new transports.Console()] })

        userService = new UserService(
            logger,
            prisma,
            new AccountQueryService(logger, new PgService(logger)),
            {
                for: () => ({ syncAccountBalances: () => Promise.resolve() }),
            },
            {} as any,
            {} as any,
            {} as any
        )

        await prisma.user.update({
            where: { id: user.id },
            data: {
                accounts: { deleteMany: {} },
            },
        })
    })

    describe('single account net worth', () => {
        it('has 0 balance prior to account start date', async () => {
            await prisma.user.update({
                where: { id: user.id },
                data: {
                    accounts: {
                        create: {
                            name: 'Test Account',
                            type: 'OTHER_ASSET',
                            provider: 'user',
                            currencyCode: 'USD',
                            startDate: date('2022-01-02'),
                            currentBalanceProvider: 200,
                            categoryProvider: 'cash',
                            balances: {
                                create: [
                                    { date: date('2022-01-01'), balance: 100 },
                                    { date: date('2022-01-02'), balance: 200 },
                                    { date: date('2022-01-03'), balance: 300 },
                                ],
                            },
                        },
                    },
                },
            })

            const expectedNetWorths: [string, number][] = [
                ['2022-01-01', 0],
                ['2022-01-02', 200],
                ['2022-01-03', 300],
            ]

            const {
                series: { data },
            } = await userService.getNetWorthSeries(user.id, '2022-01-01', '2022-01-03')

            expect(data).toHaveLength(3)

            expectedNetWorths.forEach(([date, netWorth], idx) => {
                expect(data[idx]).toMatchObject<Partial<typeof data[0]>>({
                    date,
                    netWorth: new Prisma.Decimal(netWorth),
                })
            })
        })

        it('only returns dates within requested range (inclusive)', async () => {
            await prisma.user.update({
                where: { id: user.id },
                data: {
                    accounts: {
                        create: {
                            name: 'Test Account',
                            type: 'OTHER_ASSET',
                            provider: 'user',
                            currencyCode: 'USD',
                            categoryProvider: 'cash',
                            balances: {
                                create: [
                                    { date: date('2015-07-31'), balance: 0 },
                                    { date: date('2015-08-01'), balance: 800 },
                                    { date: date('2015-09-01'), balance: 900 },
                                ],
                            },
                        },
                    },
                },
            })

            const {
                series: { data },
            } = await userService.getNetWorthSeries(user.id, '2015-07-31', '2022-02-03', 'years')

            // check bounds of returned data
            expect(data[0]).toMatchObject({
                date: '2015-07-31',
                netWorth: new Prisma.Decimal(0),
            })

            expect(data[data.length - 1]).toMatchObject({
                date: '2022-02-03',
                netWorth: new Prisma.Decimal(900),
            })
        })

        it.skip('computes the same net worth for a date regardless of the interval', async () => {
            await prisma.user.update({
                where: { id: user.id },
                data: {
                    accounts: {
                        create: [
                            {
                                name: 'Test Account A',
                                type: 'OTHER_ASSET',
                                provider: 'user',
                                currencyCode: 'USD',
                                categoryProvider: 'cash',
                                balances: {
                                    create: [
                                        { date: date('2015-07-31'), balance: 50 },
                                        { date: date('2015-08-01'), balance: 60 },
                                        { date: date('2020-02-04'), balance: 70 },
                                    ],
                                },
                            },
                            {
                                name: 'Test Account B',
                                type: 'OTHER_ASSET',
                                provider: 'user',
                                currencyCode: 'USD',
                                categoryProvider: 'cash',
                                balances: {
                                    create: [
                                        { date: date('2020-02-10'), balance: 100 },
                                        { date: date('2020-02-11'), balance: 110 },
                                        { date: date('2021-02-04'), balance: 120 },
                                    ],
                                },
                            },
                        ],
                    },
                },
            })

            const [start, end] = ['2020-02-04', '2022-02-04']

            const {
                series: { data: dataDays },
            } = await userService.getNetWorthSeries(user.id, start, end, 'days')

            const {
                series: { data: dataWeeks },
            } = await userService.getNetWorthSeries(user.id, start, end, 'weeks')

            expect(dataWeeks.length).toBeLessThan(dataDays.length)

            // ensure the start/end of each data set is the same
            expect(dataWeeks[0]).toEqual(dataDays[0])
            expect(dataWeeks[dataWeeks.length - 1]).toEqual(dataDays[dataDays.length - 1])

            // ensure the data is the same for shared dates
            dataWeeks.slice(1, -2).forEach((dataWeek) => {
                const dataDay = dataDays.find((d) => d.date === dataWeek.date)
                console.debug('date', dataWeek.date)
                expect(dataWeek).toEqual(dataDay)
            })
        })
    })

    describe('multi-account net worth', () => {
        const defaultAccountDetails = {
            type: 'OTHER_ASSET' as AccountType,
            provider: 'user' as AccountProvider,
            currencyCode: 'USD',
            categoryProvider: 'cash' as AccountCategory,
        }

        const expectedNetWorths: [string, number][] = [
            ['2021-12-30', 1841],
            ['2021-12-31', 1841],
            ['2022-01-01', 1841],
            ['2022-01-02', 1861],
            ['2022-01-03', 1861],
            ['2022-01-04', 1891],
            ['2022-01-05', 1921],
        ]

        beforeEach(async () => {
            await prisma.user.update({
                where: { id: user.id },
                data: {
                    accounts: {
                        create: [
                            // no balances, updated before range
                            {
                                ...defaultAccountDetails,
                                name: '1',
                                updatedAt: date('2022-01-01'),
                                currentBalanceProvider: 100,
                            },
                            // no balances, updated within range
                            {
                                ...defaultAccountDetails,
                                name: '11',
                                updatedAt: date('2022-01-04'),
                                currentBalanceProvider: 110,
                            },
                            // no balances, updated after range
                            {
                                ...defaultAccountDetails,
                                name: '111',
                                updatedAt: date('2022-01-06'),
                                currentBalanceProvider: 111,
                            },
                            // balances before range
                            {
                                ...defaultAccountDetails,
                                name: '2',
                                updatedAt: date('2022-01-01'),
                                currentBalanceProvider: 200,
                                balances: {
                                    create: [
                                        { date: date('2022-01-01'), balance: 200 },
                                        { date: date('2022-01-02'), balance: 220 },
                                    ],
                                },
                            },
                            // balances within range
                            {
                                ...defaultAccountDetails,
                                name: '3',
                                updatedAt: date('2022-01-01'),
                                currentBalanceProvider: 300,
                                balances: {
                                    create: [
                                        { date: date('2022-01-02'), balance: 330 },
                                        { date: date('2022-01-04'), balance: 360 },
                                        { date: date('2022-01-05'), balance: 390 },
                                    ],
                                },
                            },
                            // balances after range
                            {
                                ...defaultAccountDetails,
                                name: '4',
                                updatedAt: date('2022-01-01'),
                                currentBalanceProvider: 400,
                                balances: {
                                    create: [
                                        { date: date('2022-01-06'), balance: 440 },
                                        { date: date('2022-01-07'), balance: 480 },
                                    ],
                                },
                            },
                            // balances before + after range
                            {
                                ...defaultAccountDetails,
                                name: '5',
                                updatedAt: date('2022-01-01'),
                                currentBalanceProvider: 500,
                                balances: {
                                    create: [
                                        { date: date('2022-01-02'), balance: 550 },
                                        { date: date('2022-01-06'), balance: 599 },
                                    ],
                                },
                            },
                        ],
                    },
                },
            })
        })

        it('properly calculates net worth series', async () => {
            const {
                series: { data },
            } = await userService.getNetWorthSeries(user.id, '2021-12-30', '2022-01-05')

            expect(data).toHaveLength(7)

            expectedNetWorths.forEach(([date, netWorth], idx) => {
                expect(data[idx]).toMatchObject<Partial<typeof data[0]>>({
                    date,
                    netWorth: new Prisma.Decimal(netWorth),
                })
            })
        })

        it('properly calculates net worth for a single date', async () => {
            for (const [date, netWorth] of expectedNetWorths) {
                const data = await userService.getNetWorth(user.id, date)

                expect(data).toMatchObject({
                    date,
                    netWorth: new Prisma.Decimal(netWorth),
                })
            }
        })
    })
})
