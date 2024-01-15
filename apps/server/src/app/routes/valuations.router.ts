import { Router } from 'express'
import { z } from 'zod'
import { subject } from '@casl/ability'
import endpoint from '../lib/endpoint'
import { DateUtil } from '@maybe-finance/shared'

const router = Router()

/**
 * @swagger
 * tags:
 *   name: Valuations
 *   description: Valuations
 */

/**
 * @swagger
 * /:id:
 *   get:
 *     description: Returns valuations
 *     tags:
 *      - Valuations
 *     produces:
 *      - application/json
 *     responses:
 *       200:
 *         description: users
 */
router.get(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const valuation = await ctx.valuationService.getValuation(+req.params.id)
            ctx.ability.throwUnlessCan('read', subject('Valuation', valuation))

            return valuation
        },
    })
)

router.put(
    '/:id',
    endpoint.create({
        input: z
            .object({
                date: z.string().transform((d) => DateUtil.datetimeTransform(d).toJSDate()),
                amount: z.number(),
            })
            .optional(),
        resolve: async ({ ctx, input, req }) => {
            const valuation = await ctx.valuationService.getValuation(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Valuation', valuation))

            if (!input) return valuation

            const updatedValuation = await ctx.valuationService.updateValuation(+req.params.id, {
                date: input.date,
                ...(input.amount && { amount: input.amount }),
            })

            await ctx.accountService.syncBalances(updatedValuation.accountId)

            return updatedValuation
        },
    })
)

router.delete(
    '/:id',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const valuation = await ctx.valuationService.getValuation(+req.params.id)
            ctx.ability.throwUnlessCan('delete', subject('Valuation', valuation))

            const deletedValuation = await ctx.valuationService.deleteValuation(+req.params.id)

            await ctx.accountService.syncBalances(deletedValuation.accountId)

            return deletedValuation
        },
    })
)

export default router
