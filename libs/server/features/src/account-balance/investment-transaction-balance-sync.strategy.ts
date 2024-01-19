import type { Account, PrismaClient } from '@prisma/client'
import { Prisma } from '@prisma/client'
import type { DateTime } from 'luxon'
import type { Logger } from 'winston'
import { BalanceSyncStrategyBase } from './balance-sync.strategy'

export class InvestmentTransactionBalanceSyncStrategy extends BalanceSyncStrategyBase {
    constructor(private readonly logger: Logger, prisma: PrismaClient) {
        super(prisma)
    }

    async syncBalances(account: Account, startDate: DateTime) {
        const pAccountId = Prisma.raw(account.id.toString())
        const pStart = Prisma.raw(`'${startDate.toISODate()}'`)

        await this.prisma.$executeRaw`
          WITH holdings AS (
            -- historical (artificial) holdings (eg. user bought 100 shares, then sold 100 shares, and now no longer has a holding record)
            (
              SELECT DISTINCT ON (it.account_id, it.security_id)
                CONCAT(it.account_id, '|', it.security_id) AS id,
                it.security_id,
                0 AS quantity,
                0 AS value
              FROM
                investment_transaction it
                LEFT JOIN holding h ON h.account_id = it.account_id AND h.security_id = it.security_id
              WHERE
                it.account_id = ${pAccountId}
                AND it.security_id IS NOT NULL
                AND h.id IS NULL
            )
            UNION
            -- current holdings
            (
              SELECT
                h.id::text,
                h.security_id,
                h.quantity,
                h.value
              FROM
                holding h
                INNER JOIN security s ON s.id = h.security_id
              WHERE
                h.account_id = ${pAccountId}
                AND NOT h.excluded
                AND NOT s.is_brokerage_cash
            )
          ), holdings_daily AS (
            SELECT
              d.date,
              sp.price,
              s.shares_per_contract,
              h.quantity - SUM(COALESCE(it.quantity, 0)) OVER (PARTITION BY h.id ORDER BY it.date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as quantity,
              h.value as current_value
            FROM
              holdings h
              CROSS JOIN (
                SELECT generate_series(${pStart}, now(), '1d')::date
              ) d(date)
              INNER JOIN security s ON s.id = h.security_id
              LEFT JOIN (
                SELECT
                  time_bucket_gapfill('1d', it.date) AS date,
                  it.security_id,
                  COALESCE(SUM(CASE it.flow WHEN 'INFLOW' THEN -ABS(it.quantity) ELSE ABS(it.quantity) END), 0) AS quantity
                FROM
                  investment_transaction it
                WHERE
                  it.account_id = ${pAccountId}
                  AND it.date BETWEEN ${pStart} AND now()
                  AND ( -- filter for transactions that modify a position
                    it.category IN ('buy', 'sell', 'transfer')
                  )
                GROUP BY
                  1, 2
              ) it ON it.security_id = s.id AND it.date = d.date
              LEFT JOIN (
                SELECT
                  time_bucket_gapfill('1d', sp.date) AS date,
                  sp.security_id,
                  locf(avg(sp.price_close)) AS price
                FROM
                  security_pricing sp
                WHERE
                  sp.date BETWEEN ${pStart} AND now()
                  AND sp.security_id IN (SELECT DISTINCT security_id FROM holdings)
                GROUP BY
                  1, 2
              ) sp ON sp.security_id = s.id AND sp.date = d.date
          ), holding_balances AS (
            SELECT
              hd.date,
              SUM(COALESCE(hd.price * hd.quantity * COALESCE(hd.shares_per_contract, 1), hd.current_value)) AS balance
            FROM
              holdings_daily hd
            GROUP BY
              hd.date
          ), cash_balances AS (
            SELECT
              it.date,
              -- IF available_balance is null/0 AND account has 0 holdings THEN we use current_balance as a constant historical balance
              COALESCE(NULLIF(a.available_balance, 0), (SELECT CASE WHEN EXISTS (SELECT 1 FROM holdings) THEN 0 ELSE a.current_balance END))
              + COALESCE(SUM(it.amount) OVER (ORDER BY it.date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS balance,
              it.inflows,
              it.outflows
            FROM
              account a
              LEFT JOIN LATERAL (
                SELECT
                  time_bucket_gapfill('1d', it.date) AS date,
                  COALESCE(SUM(it.amount), 0) AS amount,
                  COALESCE(SUM(ABS(it.amount)) FILTER (WHERE it.flow = 'INFLOW'), 0) AS inflows,
                  COALESCE(SUM(ABS(it.amount)) FILTER (WHERE it.flow = 'OUTFLOW'), 0) AS outflows
                FROM
                  investment_transaction it
                WHERE
                  it.account_id = a.id
                  AND it.date BETWEEN ${pStart} AND now()
                GROUP BY
                  1
              ) it ON TRUE
            WHERE
              a.id = ${pAccountId}
          )
          INSERT INTO account_balance (account_id, date, balance, inflows, outflows)
          SELECT
            ${pAccountId},
            COALESCE(hb.date, cb.date) AS date,
            COALESCE(hb.balance + cb.balance, cb.balance, 0) AS balance,
            cb.inflows,
            cb.outflows
          FROM
            holding_balances hb
            FULL OUTER JOIN cash_balances cb ON cb.date = hb.date
          ON CONFLICT (account_id, date) DO UPDATE
          SET
            balance = EXCLUDED.balance,
            inflows = EXCLUDED.inflows,
            outflows = EXCLUDED.outflows;
        `
    }
}
