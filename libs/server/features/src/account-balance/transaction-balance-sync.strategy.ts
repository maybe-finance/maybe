import type { DateTime } from 'luxon'
import type { Account, PrismaClient } from '@prisma/client'
import type { Logger } from 'winston'
import { BalanceSyncStrategyBase } from './balance-sync.strategy'

export class TransactionBalanceSyncStrategy extends BalanceSyncStrategyBase {
    constructor(private readonly logger: Logger, prisma: PrismaClient) {
        super(prisma)
    }

    async syncBalances(account: Account, startDate: DateTime) {
        const pAccountId = account.id
        const pStart = startDate.toJSDate()

        await this.prisma.$executeRaw`
          INSERT INTO account_balance (account_id, date, balance, inflows, outflows)
          SELECT
            t.account_id,
            t.date,
            (
              COALESCE(a.current_balance, a.available_balance) +
              (CASE WHEN a.classification = 'liability' THEN -1 ELSE 1 END) *
              COALESCE(SUM(t.net_flows) OVER (PARTITION BY t.account_id ORDER BY t.date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0)
            ) as balance,
            SUM(t.inflows) OVER (PARTITION BY t.account_id, t.date) as inflows,
            SUM(t.outflows) OVER (PARTITION BY t.account_id, t.date) as outflows
          FROM
            (
              SELECT
                time_bucket_gapfill('1d', t.date) AS date,
                t.account_id,
                COALESCE(SUM(t.amount), 0) as net_flows,
		            COALESCE(SUM(ABS(amount)) FILTER (WHERE flow = 'INFLOW'), 0) as inflows,
		            COALESCE(SUM(amount) FILTER (WHERE flow = 'OUTFLOW'), 0) as outflows
              FROM
                transaction t
              WHERE
                t.account_id = ${pAccountId}
                AND t.date BETWEEN ${pStart} AND now()
              GROUP BY
                1, 2
            ) t
            INNER JOIN account a ON a.id = t.account_id
          WHERE
            COALESCE(a.current_balance, a.available_balance) IS NOT NULL
          ON CONFLICT (account_id, date) DO UPDATE
          SET
            inflows = EXCLUDED.inflows,
            outflows = EXCLUDED.outflows,
            balance = EXCLUDED.balance
        `
    }
}
