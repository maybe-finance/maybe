import type { Account, User } from '@prisma/client'
import { PrismaClient, Prisma } from '@prisma/client'
import { DateTime } from 'luxon'
import { resetUser } from './utils/user'

const prisma = new PrismaClient()

describe('prisma', () => {
    let user: User
    let account: Account

    beforeEach(async () => {
        // Clears old user and data, creates new user
        user = await resetUser()
        account = await prisma.account.create({
            data: {
                userId: user.id,
                type: 'OTHER_ASSET',
                provider: 'user',
                name: 'TEST_DATA_TYPES',
                startDate: DateTime.fromISO('2022-09-01').toJSDate(),
                currentBalanceProvider: 123,
            },
        })
    })

    describe('$executeRaw', () => {
        it('can serialize list of partially nullable values', async () => {
            const count = await prisma.$executeRaw`
              UPDATE account AS a
              SET
                available_balance_provider = u.available_balance_provider
              FROM (
                VALUES
                  ${Prisma.join(
                      [
                          [account.id, null],
                          [account.id, new Prisma.Decimal(12.34)],
                          [account.id, null],
                      ].map(([accountId, availableBalanceProvider]) => {
                          return Prisma.sql`(
                            ${accountId},
                            ${availableBalanceProvider}
                          )`
                      })
                  )}
              ) AS u(id, available_balance_provider)
              WHERE
                a.id = u.id;
            `

            expect(count).toBe(1)
        })

        it(`can serialize list of all nullable values w/ casts`, async () => {
            const count = await prisma.$executeRaw`
              UPDATE account AS a
              SET
              available_balance_provider = u.available_balance_provider
              FROM (
                VALUES
                  ${Prisma.join(
                      [[account.id, null]].map(([accountId, availableBalanceProvider]) => {
                          return Prisma.sql`(
                            ${accountId},
                            ${availableBalanceProvider}::numeric
                          )`
                      })
                  )}
              ) AS u(id, available_balance_provider)
              WHERE
                a.id = u.id;
            `

            expect(count).toBe(1)
        })

        it(`cannot serialize list of all nullable values w/o casts`, async () => {
            expect(prisma.$executeRaw`
              UPDATE account AS a
              SET
                available_balance_provider = u.available_balance_provider
              FROM (
                VALUES
                  ${Prisma.join(
                      [[account.id, null]].map(([accountId, availableBalanceProvider]) => {
                          return Prisma.sql`(
                            ${accountId},
                            ${availableBalanceProvider}
                          )`
                      })
                  )}
              ) AS u(id, available_balance_provider)
              WHERE
                a.id = u.id;
            `).rejects.toThrow()
        })
    })

    describe('$queryRaw', () => {
        it('can serialize function parameters w/ casts', async () => {
            const rows = await prisma.$queryRaw<any[]>`
              SELECT
                a.*,
                abg.*
              FROM
                account a,
                account_balances_gapfilled(
                  ${'2022-09-01'}::date,
                  ${'2022-10-01'}::date,
                  ${'1 day'}::interval,
                  ${[account.id]}::int[]
                ) abg
              WHERE
                a.id = ${account.id}
            `

            expect(rows.length).toBeGreaterThan(0)
        })

        it('cannot serialize function parameters w/o casts', async () => {
            expect(prisma.$queryRaw<any[]>`
              SELECT
                a.*,
                abg.*
              FROM
                account a,
                account_balances_gapfilled(
                  ${'2022-09-01'},
                  ${'2022-10-01'},
                  ${'1 day'}::interval,
                  ${[account.id]}
                ) abg
              WHERE
                a.id = ${account.id}
            `).rejects.toThrow()
        })

        it('can deserialize data types', async () => {
            const [data] = await prisma.$queryRaw<Record<string, any>[]>`
              SELECT
                created_at, -- datetime
                current_balance, -- decimal
                COALESCE(available_balance, 0) AS "available_balance", -- decimal
                start_date, -- date
                (SELECT COUNT(*) FROM account) AS "count" -- int4
              FROM
                account
              WHERE
                id = ${account.id}
            `

            expect(data.created_at).toBeInstanceOf(Date)
            expect(data.current_balance).toBeInstanceOf(Prisma.Decimal)
            expect(data.available_balance).toBeInstanceOf(Prisma.Decimal)
            expect(data.start_date).toBeInstanceOf(Date)
            expect(typeof data.count).toBe('bigint')
        })
    })
})
