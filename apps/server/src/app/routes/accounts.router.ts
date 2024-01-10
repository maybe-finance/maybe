import type { Account } from '@prisma/client'
import type { SharedType } from '@maybe-finance/shared'
import { Router } from 'express'
import { subject } from '@casl/ability'
import { z } from 'zod'
import { DateUtil } from '@maybe-finance/shared'
import {
    AccountCreateSchema,
    AccountUpdateSchema,
    InvestmentTransactionCategorySchema,
} from '@maybe-finance/server/features'
import endpoint from '../lib/endpoint'
import keyBy from 'lodash/keyBy'
import merge from 'lodash/merge'

const router = Router()

router.get(
    '/',
    endpoint.create({
        resolve: async ({ ctx }) => {
            return ctx.accountService.getAll(ctx.user!.id)
        },
    })
)

router.post(
    '/',
    endpoint.create({
        input: AccountCreateSchema,
        resolve: async ({ input, ctx }) => {
            ctx.ability.throwUnlessCan('create', 'Account')

            let account: Account

            switch (input.type) {
                case 'LOAN': {
                    const { currentBalance, ...rest } = input

                    account = await ctx.accountService.create({
                        ...rest,
                        userId: ctx.user!.id,
                        currentBalanceProvider: currentBalance,
                        currentBalanceStrategy: 'current',
                    })

                    break
                }
                default: {
                    const {
                        valuations: { originalBalance, currentBalance, currentDate },
                        startDate,
                        ...rest
                    } = input

                    const initialValuations = [
                        {
                            source: 'manual',
                            date: startDate!,
                            amount: originalBalance,
                        },
                    ]

                    if (
                        startDate &&
                        currentBalance &&
                        !DateUtil.isSameDate(DateUtil.datetimeTransform(startDate), currentDate)
                    ) {
                        initialValuations.push({
                            source: 'manual',
                            date: currentDate.toJSDate(),
                            amount: currentBalance,
                        })
                    }

                    account = await ctx.accountService.create(
                        {
                            ...rest,
                            userId: ctx.user!.id,
                            currentBalanceProvider: currentBalance,
                            currentBalanceStrategy: 'current',
                        },
                        {
                            create: initialValuations,
                        }
                    )

                    break
                }
            }

            await ctx.accountService.syncBalances(account.id)

            return account
        },
    })
)

router.get(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const account = await ctx.accountService.getAccountDetails(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Account', account))
            return account
        },
    })
)

router.put(
    '/:id',
    endpoint.create({
        input: AccountUpdateSchema,
        resolve: async ({ input, ctx, req }) => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Account', account))
            const updatedAccount = await ctx.accountService.update(account.id, {
                ...input.data,
                ...('currentBalance' in input.data
                    ? {
                          currentBalance: undefined,
                          currentBalanceProvider: input.data.currentBalance,
                          currentBalanceStrategy: 'current',
                      }
                    : {}),
            })
            await ctx.accountService.syncBalances(updatedAccount.id)
            return updatedAccount
        },
    })
)

router.delete(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('delete', subject('Account', account))
            return ctx.accountService.delete(account.id)
        },
    })
)

router.get(
    '/:id/balances',
    endpoint.create({
        input: z
            .object({
                start: z.string().transform(DateUtil.dateTransform),
                end: z.string().transform(DateUtil.dateTransform),
            })
            .partial(),
        resolve: async ({ ctx, input, req }) => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Account', account))
            return ctx.accountService.getBalances(account.id, input.start, input.end)
        },
    })
)

router.get(
    '/:id/returns',
    endpoint.create({
        input: z.object({
            start: z.string().transform((v) => DateUtil.datetimeTransform(v)),
            end: z.string().transform((v) => DateUtil.datetimeTransform(v)),
            compare: z
                .string()
                .optional()
                .transform((v) => v?.split(',')), // in format of /accounts/:id/returns?compare=VOO,AAPL,TSLA
        }),
        resolve: async ({ ctx, input, req }): Promise<SharedType.AccountReturnResponse> => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Account', account))

            const returnSeries: SharedType.AccountReturnTimeSeriesData[] =
                await ctx.accountService.getReturns(
                    account.id,
                    input.start.toISODate(),
                    input.end.toISODate()
                )

            const baseSeries = {
                interval: 'days' as SharedType.TimeSeriesInterval,
                start: input.start.toISODate(),
                end: input.end.toISODate(),
            }

            if (!input.compare || input.compare.length < 1)
                return {
                    ...baseSeries,
                    data: returnSeries,
                }

            const comparisonData = await Promise.allSettled(
                input.compare.map(async (ticker) => {
                    return {
                        ticker,
                        pricing: await ctx.marketDataService.getDailyPricing(
                            { symbol: ticker, plaidType: null, currencyCode: 'USD' },
                            input.start,
                            input.end
                        ),
                    }
                })
            )

            const comparisonPrices = comparisonData
                .filter(
                    (
                        data
                    ): data is PromiseFulfilledResult<{
                        ticker: string
                        pricing: SharedType.DailyPricing[]
                    }> => {
                        if (data.status === 'rejected') {
                            ctx.logger.warn('Unable to generate comparison data', {
                                reason: data.reason,
                            })
                        }

                        return data.status === 'fulfilled'
                    }
                )
                .map((data) => {
                    return data.value.pricing.map((price) => ({
                        date: price.date.toISODate(),
                        [data.value.ticker]: price.priceClose
                            .dividedBy(data.value.pricing[0].priceClose)
                            .minus(1),
                    }))
                })

            // Performs a "left join" of prices by ticker
            const merged: Record<
                string,
                SharedType.AccountReturnResponse['data'][number]['comparisons']
            > = merge(
                keyBy(
                    returnSeries.map((v) => ({ date: v.date })), // ensures we have a key for every single day
                    'date'
                ),
                ...comparisonPrices.map((prices) => keyBy(prices, 'date'))
            )

            return {
                ...baseSeries,
                data: returnSeries.map((rs) => {
                    return {
                        ...rs,
                        comparisons: merged[rs.date],
                    }
                }),
            }
        },
    })
)

router.get(
    '/:id/transactions',
    endpoint.create({
        input: z
            .object({
                start: z.string().transform(DateUtil.datetimeTransform),
                end: z.string().transform(DateUtil.datetimeTransform),
                page: z.string().transform((val) => parseInt(val)),
            })
            .partial(),
        resolve: async ({ ctx, input, req }) => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Account', account))
            return ctx.accountService.getTransactions(
                account.id,
                input.page,
                input.start,
                input.end
            )
        },
    })
)

router.get(
    '/:id/valuations',
    endpoint.create({
        input: z
            .object({
                start: z.string().transform(DateUtil.datetimeTransform),
                end: z.string().transform(DateUtil.datetimeTransform),
            })
            .partial(),
        resolve: async ({ ctx, input, req }) => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Account', account))
            return ctx.valuationService.getValuations(account.id, input.start, input.end)
        },
    })
)

router.post(
    '/:id/valuations',
    endpoint.create({
        input: z.object({
            date: z.string().transform(DateUtil.datetimeTransform),
            amount: z.number(),
        }),
        resolve: async ({ ctx, input: { date, amount }, req }) => {
            const account = await ctx.accountService.get(+req.params.id)

            ctx.ability.throwUnlessCan('update', subject('Account', account))

            if (!date) throw new Error('Invalid valuation date')

            const valuation = await ctx.valuationService.createValuation({
                amount,
                date: date.toJSDate(),
                accountId: +req.params.id,
                source: 'manual',
            })

            await ctx.accountService.syncBalances(+req.params.id)

            return valuation
        },
    })
)

router.get(
    '/:id/holdings',
    endpoint.create({
        input: z
            .object({
                page: z.string().transform((val) => parseInt(val)),
            })
            .partial(),
        resolve: async ({ ctx, input: { page }, req }) => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Account', account))
            return ctx.accountService.getHoldings(account.id, page)
        },
    })
)

router.get(
    '/:id/investment-transactions',
    endpoint.create({
        input: z
            .object({
                page: z.string().transform((val) => parseInt(val)),
                start: z.string().transform(DateUtil.datetimeTransform).optional(),
                end: z.string().transform(DateUtil.datetimeTransform).optional(),
                category: InvestmentTransactionCategorySchema.optional(),
            })
            .partial(),
        resolve: async ({ ctx, input, req }) => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Account', account))
            return ctx.accountService.getInvestmentTransactions(
                account.id,
                input.page,
                input.start,
                input.end,
                input.category
            )
        },
    })
)

router.get(
    '/:id/insights',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Account', account))
            return ctx.insightService.getAccountInsights({ accountId: account.id })
        },
    })
)

router.post(
    '/:id/sync',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Account', account))
            return ctx.accountService.sync(+req.params.id)
        },
    })
)

// Syncs account balances without triggering a background worker (syncs balances much faster, ideal for smaller updates such as editing an account valuation)
router.post(
    '/:id/sync/balances',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const account = await ctx.accountService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Account', account))
            return ctx.accountService.syncBalances(+req.params.id)
        },
    })
)

export default router
