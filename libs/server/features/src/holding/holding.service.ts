import type { Logger } from 'winston'
import type { PrismaClient, Holding } from '@prisma/client'
import type { Prisma } from '@prisma/client'
import type { SharedType } from '@maybe-finance/shared'
import { DbUtil } from '@maybe-finance/server/shared'

export class HoldingService {
    constructor(private readonly logger: Logger, private readonly prisma: PrismaClient) {}

    async get(id: Holding['id']) {
        return this.prisma.holding.findUniqueOrThrow({
            where: { id },
            include: { account: { include: { accountConnection: true } } },
        })
    }

    async getHoldingDetails(id: Holding['id']): Promise<SharedType.AccountHolding> {
        const [he] = await this.prisma.$queryRaw<
            Array<
                SharedType.HoldingEnriched & {
                    cost_basis_user: Prisma.Decimal | null
                    cost_basis_provider: Prisma.Decimal | null
                }
            >
        >`
            SELECT
              he.*,
              h.security_id,
              h.cost_basis_user,
              h.cost_basis_provider,
              s.name,
              s.symbol
            FROM
              holdings_enriched he
              INNER JOIN security s ON s.id = he.security_id
              INNER JOIN holding h ON h.id = he.id
            WHERE
              h.id = ${id};
        `

        return {
            id,
            securityId: he.security_id,
            name: he.name,
            symbol: he.symbol,
            quantity: DbUtil.toDecimal(he.quantity),
            sharesPerContract: DbUtil.toDecimal(he.shares_per_contract),
            costBasis: DbUtil.toDecimal(he.cost_basis),
            costBasisUser: DbUtil.toDecimal(he.cost_basis_user),
            costBasisProvider: DbUtil.toDecimal(he.cost_basis_provider),
            price: DbUtil.toDecimal(he.price),
            value: DbUtil.toDecimal(he.value),
            trend: {
                total: he.cost_basis ? DbUtil.calculateTrend(he.cost_basis, he.value) : null,
                today: he.price_prev
                    ? DbUtil.calculateTrend(he.price_prev.times(he.quantity), he.value)
                    : null,
            },
            excluded: he.excluded,
        }
    }

    async update(id: Holding['id'], data: Prisma.HoldingUncheckedUpdateInput) {
        const holding = await this.prisma.holding.update({
            where: { id },
            data,
        })

        this.logger.info(`Updated holding id=${id} account=${holding.accountId}`)

        return holding
    }
}
