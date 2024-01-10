import { Router } from 'express'
import { subject } from '@casl/ability'
import { HoldingUpdateInputSchema } from '@maybe-finance/server/features'
import endpoint from '../lib/endpoint'

const router = Router()

router.get(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const holding = await ctx.holdingService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Holding', holding))

            return ctx.holdingService.getHoldingDetails(holding.id)
        },
    })
)

router.get(
    '/:id/insights',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const holding = await ctx.holdingService.get(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Holding', holding))

            return ctx.insightService.getHoldingInsights({ holding })
        },
    })
)

router.put(
    '/:id',
    endpoint.create({
        input: HoldingUpdateInputSchema,
        resolve: async ({ input, ctx, req }) => {
            const holding = await ctx.holdingService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Holding', holding))

            const updatedHolding = await ctx.holdingService.update(+req.params.id, input)

            await ctx.accountService.syncBalances(holding.accountId)

            return updatedHolding
        },
    })
)

export default router
