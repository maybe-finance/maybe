import type { PrismaClient, User } from '@prisma/client'
import { InvestmentTransactionCategory, Prisma } from '@prisma/client'
import _ from 'lodash'
import { DateTime } from 'luxon'
import { parseCsv } from './csv'
import { join } from 'path'

const date = (s: string) => DateTime.fromISO(s, { zone: 'utc' }).toJSDate()

const portfolios: Record<string, Partial<Prisma.AccountUncheckedCreateInput>> = {
    'portfolio-1': {
        startDate: date('2021-12-31'),
        currentBalanceProvider: 8462,
        availableBalanceProvider: 290,
    },
    'portfolio-2': {
        startDate: date('2022-07-01'),
        currentBalanceProvider: 26000,
        availableBalanceProvider: 8000,
    },
}

const investmentTransactionCategoryByType: Record<string, InvestmentTransactionCategory> = {
    BUY: InvestmentTransactionCategory.buy,
    SELL: InvestmentTransactionCategory.sell,
    DIVIDEND: InvestmentTransactionCategory.dividend,
    DEPOSIT: InvestmentTransactionCategory.transfer,
    WITHDRAW: InvestmentTransactionCategory.transfer,
}

export async function createTestInvestmentAccount(
    prisma: PrismaClient,
    user: User,
    portfolio: 'portfolio-1' | 'portfolio-2'
) {
    const transactionsData = await parseCsv<'date' | 'type' | 'ticker' | 'qty'>(
        join(__dirname, `../test-data/${portfolio}/transactions.csv`)
    )
    const securitiesData = await parseCsv<'date' | 'ticker' | 'price'>(
        join(__dirname, `../test-data/${portfolio}/securities.csv`)
    )
    const holdingsData = await parseCsv<'ticker' | 'qty' | 'costBasis' | 'value'>(
        join(__dirname, `../test-data/${portfolio}/holdings.csv`)
    )

    const [, ...securities] = await prisma.$transaction([
        prisma.security.deleteMany({
            where: {
                symbol: {
                    in: _(securitiesData)
                        .map((s) => s.ticker)
                        .uniq()
                        .value(),
                },
                name: {
                    startsWith: 'TEST[',
                },
            },
        }),
        ..._(securitiesData)
            .groupBy((s) => s.ticker)
            .map((rows, ticker) =>
                prisma.security.create({
                    data: {
                        symbol: ticker,
                        name: `TEST[${ticker}]`,
                        pricing: {
                            createMany: {
                                data: rows
                                    .filter((s) => s.ticker === ticker)
                                    .map((s) => ({
                                        date: date(s.date),
                                        priceClose: s.price,
                                    })),
                            },
                        },
                    },
                })
            )
            .value(),
    ])

    return prisma.account.create({
        data: {
            ...portfolios[portfolio],
            userId: user.id,
            name: portfolio,
            type: 'INVESTMENT',
            provider: 'user',
            holdings: {
                create: holdingsData.map((h) => {
                    const security = securities.find((s) => s.symbol === h.ticker)
                    return {
                        security: security
                            ? { connect: { id: security.id } }
                            : { create: { symbol: h.ticker } },
                        quantity: h.qty,
                        costBasisProvider: new Prisma.Decimal(h.costBasis).times(h.qty),
                        value: h.value,
                    }
                }),
            },
            investmentTransactions: {
                createMany: {
                    data: transactionsData.map((it) => {
                        const price = securitiesData.find(
                            (s) => s.date === it.date && s.ticker === it.ticker
                        )?.price

                        return {
                            securityId: securities.find((s) => it.ticker === s.symbol)?.id,
                            date: date(it.date),
                            name: `${it.type} ${it.ticker}`,
                            amount: price ? new Prisma.Decimal(price).times(it.qty) : it.qty,
                            quantity: price ? it.qty : 0,
                            price: price ?? 0,
                            category:
                                investmentTransactionCategoryByType[it.type] ??
                                InvestmentTransactionCategory.other,
                        }
                    }),
                },
            },
        },
    })
}
