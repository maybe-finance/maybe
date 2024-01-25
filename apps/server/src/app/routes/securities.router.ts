import { Router } from 'express'
import { DateTime } from 'luxon'
import env from '../../env'
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

            if (env.NX_POLYGON_API_KEY) {
                await ctx.queueService.getQueue('sync-security').add('sync-us-stock-tickers', {})
                return { success: true }
            } else {
                return { success: false, message: 'No Polygon API key found' }
            }
        },
    })
)

router.post(
    '/sync/stock-pricing',
    endpoint.create({
        resolve: async ({ ctx }) => {
            ctx.ability.throwUnlessCan('manage', 'Security')

            if (env.NX_POLYGON_API_KEY) {
                await ctx.queueService.getQueue('sync-security').add('sync-all-securities', {})
                return { success: true }
            } else {
                return { success: false, message: 'No Polygon API key found' }
            }
        },
    })
)

export default router
