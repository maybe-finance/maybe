import { Router } from 'express'
import { DateTime } from 'luxon'
import endpoint from '../lib/endpoint'

const router = Router()

router.get(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            ctx.ability.throwUnlessCan('read', 'Security')

            return await ctx.prisma.security.findUniqueOrThrow({
                where: { id: +req.params.id },
                include: {
                    pricing: {
                        where: {
                            date: {
                                gte: DateTime.now().minus({ weeks: 52 }).toJSDate(),
                                lte: DateTime.now().toJSDate(),
                            },
                        },
                        orderBy: {
                            date: 'asc',
                        },
                    },
                },
            })
        },
    })
)

router.get(
    '/:id/details',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            ctx.ability.throwUnlessCan('read', 'Security')

            const security = await ctx.prisma.security.findUniqueOrThrow({
                where: { id: +req.params.id },
            })

            return await ctx.marketDataService.getSecurityDetails(security)
        },
    })
)

router.post(
    '/sync/us-stock-tickers',
    endpoint.create({
        resolve: async ({ ctx }) => {
            ctx.ability.throwUnlessCan('manage', 'Security')

            await ctx.queueService
                .getQueue('sync-security')
                .addBulk([{ name: 'sync-us-stock-tickers', data: {} }])

            return { success: true }
        },
    })
)

export default router
