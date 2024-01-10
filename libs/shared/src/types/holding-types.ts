import type { Holding, Prisma, Security } from '@prisma/client'

export type HoldingInsights = {
    holding: Holding
    dividends: Prisma.Decimal | null
    allocation: Prisma.Decimal | null
}

export type HoldingEnriched = Pick<Holding, 'id' | 'quantity' | 'value' | 'excluded'> & {
    name: Security['name']
    security_id: Security['id']
    symbol: Security['symbol']
    shares_per_contract: Security['sharesPerContract']
    cost_basis: Prisma.Decimal | null
    cost_basis_per_share: Prisma.Decimal | null
    price: Prisma.Decimal
    price_prev: Prisma.Decimal | null
}
