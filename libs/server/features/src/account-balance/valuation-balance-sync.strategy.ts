import type { DateTime } from 'luxon'
import type { Account, PrismaClient } from '@prisma/client'
import type { Logger } from 'winston'
import { BalanceSyncStrategyBase } from './balance-sync.strategy'

export class ValuationBalanceSyncStrategy extends BalanceSyncStrategyBase {
    constructor(private readonly logger: Logger, prisma: PrismaClient) {
        super(prisma)
    }

    async syncBalances(account: Account, startDate: DateTime) {
        const pAccountId = account.id
        const pStart = startDate.toJSDate()

        await this.prisma.$executeRaw`
          INSERT INTO account_balance (account_id, date, balance)
          SELECT
            v.account_id,
            v.date,
            COALESCE(v.interpolate, v.locf) AS balance
          FROM
            (
              SELECT
                time_bucket_gapfill('1d', v.date) AS date,
                v.account_id,
                interpolate(avg(v.amount)),
                locf(avg(v.amount))
              FROM
                valuation v
              WHERE
                v.account_id = ${pAccountId}
                AND v.date BETWEEN ${pStart} AND now()
              GROUP BY
                1, 2
            ) v
          ON CONFLICT (account_id, date) DO UPDATE
          SET inflows = EXCLUDED.inflows, outflows = EXCLUDED.outflows, balance = EXCLUDED.balance
        `
    }
}
