import { DateTime } from 'luxon'
import type { Account, PrismaClient } from '@prisma/client'
import { Prisma } from '@prisma/client'
import type { Logger } from 'winston'
import { BalanceSyncStrategyBase } from './balance-sync.strategy'

export class LoanBalanceSyncStrategy extends BalanceSyncStrategyBase {
    constructor(private readonly logger: Logger, prisma: PrismaClient) {
        super(prisma)
    }

    async syncBalances(account: Account, startDate: DateTime) {
        if (!account.loan) {
            this.logger.warn(`account ${account.id} is missing loan data, skipping balance sync`)
            return
        }

        const pAccountId = account.id
        const pStart = Prisma.raw(`'${startDate.toISODate()}'`)

        const {
            _min: { date: minDate },
        } = await this.prisma.transaction.aggregate({
            where: { accountId: account.id },
            _min: { date: true },
        })

        // the cutoff date is one day prior to the first date we have transaction data for
        // this serves as our stopping point for interpolation from the origination date
        const pCutoffDate = minDate
            ? Prisma.raw(
                  `'${DateTime.fromJSDate(minDate, { zone: 'utc' })
                      .minus({ days: 1 })
                      .toISODate()}'`
              )
            : Prisma.raw('now()')

        await this.prisma.$executeRaw`
          WITH interpolated_balances AS (
            -- interpolate balances from origination -> earliest transaction
            SELECT
              time_bucket_gapfill('1d', b.date) AS "date",
              interpolate(avg(b.balance)) AS "balance"
            FROM
              (
                SELECT
                  (a.loan->>'originationDate')::date AS "date",
                  (a.loan->'originationPrincipal')::numeric AS "balance"
                FROM
                  account a
                WHERE
                  a.id = ${pAccountId} AND a.loan IS NOT NULL
                UNION
                SELECT
                  ${pCutoffDate}::date AS "date",
                  COALESCE(a.current_balance - COALESCE((SELECT SUM(amount) FROM "transaction" WHERE account_id = a.id AND date > ${pCutoffDate}), 0), 0) AS "balance"
                FROM
                  account a
                WHERE
                  a.id = ${pAccountId}
              ) b
            WHERE
              b.date >= ${pStart}
              AND b.date <= ${pCutoffDate}
            GROUP BY
              1
          ), txn_balances AS (
            -- compute balances from now -> earliest transaction (using standard transaction calculation approach)
            SELECT
              t.date,
              (
                COALESCE(a.current_balance, a.available_balance) -
                COALESCE(SUM(t.net_flows) OVER (ORDER BY t.date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0)
              ) as balance,
              SUM(t.inflows) OVER (PARTITION BY t.date) as inflows,
              SUM(t.outflows) OVER (PARTITION BY t.date) as outflows
            FROM
              account a,
              (
                SELECT
                  time_bucket_gapfill('1d', t.date) AS date,
                  COALESCE(SUM(t.amount), 0) as net_flows,
                  COALESCE(SUM(ABS(amount)) FILTER (WHERE flow = 'INFLOW'), 0) as inflows,
                  COALESCE(SUM(amount) FILTER (WHERE flow = 'OUTFLOW'), 0) as outflows
                FROM
                  transaction t
                WHERE
                  t.account_id = ${pAccountId}
                  AND t.date > ${pCutoffDate}
                  AND t.date <= now()
                GROUP BY
                  1
              ) t
            WHERE
              a.id = ${pAccountId}
          ), combined_balances AS (
            -- combine results
            SELECT
              date,
              balance,
              NULL AS "inflows",
              NULL AS "outflows"
            FROM
              interpolated_balances ib
            UNION
            SELECT
              date,
              balance,
              inflows,
              outflows
            FROM
              txn_balances tb
          )
          INSERT INTO account_balance (account_id, date, balance, inflows, outflows)
          SELECT
            ${pAccountId},
            date,
            balance,
            inflows,
            outflows
          FROM
            combined_balances
          WHERE
            balance IS NOT NULL -- balance can be NULL for accounts w/o valid loan info
          ON CONFLICT (account_id, date) DO UPDATE
          SET
            balance = EXCLUDED.balance,
            inflows = EXCLUDED.inflows,
            outflows = EXCLUDED.outflows
        `
    }
}
