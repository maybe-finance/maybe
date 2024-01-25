import type { Prisma, Security, SecurityPricing } from '@prisma/client'
import type { DateTime } from 'luxon'

export type { Security, SecurityPricing }

export type SecurityWithPricing = Security & {
    pricing: SecurityPricing[]
}

export type SecuritySymbolExchange = {
    symbol: string
    exchange: string
}

export type SecurityDetails = {
    day?: {
        open?: Prisma.Decimal
        prevClose?: Prisma.Decimal
        high?: Prisma.Decimal
        low?: Prisma.Decimal
    }
    year?: {
        high?: Prisma.Decimal
        low?: Prisma.Decimal
        volume?: Prisma.Decimal
        dividends?: Prisma.Decimal
    }
    marketCap?: Prisma.Decimal
    peRatio?: Prisma.Decimal
    expenseRatio?: Prisma.Decimal
    eps?: Prisma.Decimal
}

export type DailyPricing = {
    date: DateTime
    priceClose: Prisma.Decimal
}
