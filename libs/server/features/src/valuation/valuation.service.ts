import type { Logger } from 'winston'
import type { Account, PrismaClient, Valuation } from '@prisma/client'
import type { Prisma } from '@prisma/client'
import type { DateTime } from 'luxon'
import type { SharedType } from '@maybe-finance/shared'
import type { IAccountQueryService } from '../account'
import { SharedUtil } from '@maybe-finance/shared'
import { DbUtil } from '@maybe-finance/server/shared'

export class ValuationService {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly queryService: IAccountQueryService
    ) {}

    async getValuations(
        accountId: Account['id'],
        start?: DateTime,
        end?: DateTime
    ): Promise<SharedType.AccountValuationsResponse> {
        const [valuations, trends] = await Promise.all([
            this.prisma.valuation.findMany({
                where: {
                    accountId,
                    date: {
                        gte: start?.toJSDate(),
                        lte: end?.toJSDate(),
                    },
                },
                orderBy: { date: 'asc' },
            }),
            this.queryService.getValuationTrends(accountId, start, end),
        ])

        return {
            valuations: valuations.map((valuation) => {
                const trend = trends.find((t) => t.valuation_id === valuation.id)
                return {
                    ...valuation,
                    trend: trend
                        ? {
                              period: DbUtil.toTrend(trend.period_change, trend.period_change_pct),
                              total: DbUtil.toTrend(trend.total_change, trend.total_change_pct),
                          }
                        : null,
                }
            }),
            trends: trends
                .filter((trend) => !SharedUtil.nonNull(trend.valuation_id))
                .map((trend) => ({
                    date: trend.date,
                    amount: trend.amount,
                    period: DbUtil.toTrend(trend.period_change, trend.period_change_pct),
                    total: DbUtil.toTrend(trend.total_change, trend.total_change_pct),
                })),
        }
    }

    async getValuation(id: Valuation['id']) {
        return await this.prisma.valuation.findUniqueOrThrow({
            where: { id },
            include: { account: true },
        })
    }

    async createValuation(data: Prisma.ValuationUncheckedCreateInput) {
        return await this.prisma.valuation.create({ data })
    }

    async updateValuation(
        id: Valuation['id'],
        data: { date?: Date; amount?: Prisma.Decimal | number }
    ) {
        return await this.prisma.valuation.update({
            where: { id },
            data,
        })
    }

    async deleteValuation(id: Valuation['id']) {
        return await this.prisma.valuation.delete({ where: { id } })
    }
}
