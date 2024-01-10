import { DateUtil } from '@maybe-finance/shared'
import type { Account, PrismaClient } from '@prisma/client'
import { DateTime } from 'luxon'

export interface IBalanceSyncStrategy {
    syncAccountBalances(account: Account): Promise<void>
}

export abstract class BalanceSyncStrategyBase implements IBalanceSyncStrategy {
    constructor(protected readonly prisma: PrismaClient) {}

    async syncAccountBalances(account: Account) {
        const [{ date }] = await this.prisma.$queryRaw<
            [{ date: Date }]
        >`SELECT account_value_start_date(${account.id}::int) AS date`

        const startDate = DateTime.max(
            DateUtil.MIN_SUPPORTED_DATE,
            DateTime.fromJSDate(date, { zone: 'utc' })
        )

        await this.syncBalances(account, startDate)
    }

    protected abstract syncBalances(account: Account, startDate: DateTime): Promise<void>
}

export interface IBalanceSyncStrategyFactory {
    for(account: Account): IBalanceSyncStrategy
}

export class BalanceSyncStrategyFactory implements IBalanceSyncStrategyFactory {
    constructor(private readonly strategies: Record<Account['type'], IBalanceSyncStrategy>) {}

    for(account: Account): IBalanceSyncStrategy {
        const strategy = this.strategies[account.type]
        if (!strategy) throw new Error(`cannot find strategy for account: ${account.id}`)
        return strategy
    }
}
