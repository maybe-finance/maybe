import { Router } from 'express'
import { z } from 'zod'
import endpoint from '../lib/endpoint'

const router = Router()

/**
 * @swagger
 * tags:
 *   name: Institutions
 *   description: Institutions
 */

/**
 * @swagger
 * /:
 *   get:
 *     description: Returns instriutions
 *     tags:
 *      - Institutions
 *     produces:
 *      - application/json
 *     responses:
 *       200:
 *         description: users
 */
router.get(
    '/',
    endpoint.create({
        input: z
            .object({
                q: z.string(),
                page: z.string().transform((val) => parseInt(val)),
            })
            .partial(),
        resolve: async ({ ctx, input }) => {
            ctx.ability.throwUnlessCan('read', 'Institution')

            return ctx.institutionService.getAll({ query: input.q, page: input.page })
        },
    })
)

router.post(
    '/sync',
    endpoint.create({
        resolve: async ({ ctx }) => {
            ctx.ability.throwUnlessCan('update', 'Institution')

            // Sync all Plaid + Finicity institutions
            await ctx.queueService.getQueue('sync-institution').addBulk([
                { name: 'sync-plaid-institutions', data: {} },
                { name: 'sync-finicity-institutions', data: {} },
            ])

            return { success: true }
        },
    })
)

router.post(
    '/deduplicate',
    endpoint.create({
        resolve: async ({ ctx }) => {
            ctx.ability.throwUnlessCan('manage', 'Institution')

            await ctx.institutionService.deduplicateInstitutions()

            return { success: true }
        },
    })
)

export default router
