import { Router } from 'express'
import { z } from 'zod'
import { DateUtil } from '@maybe-finance/shared'
import endpoint from '../lib/endpoint'

const router = Router()

/**
 * @swagger
 * tags:
 *   name: Account Rollups
 *   description: Account rollups
 */

/**
 * @swagger
 * /:
 *   get:
 *     description: Returns accounts
 *     tags:
 *      - Account Rollups
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
                start: z.string().transform(DateUtil.dateTransform),
                end: z.string().transform(DateUtil.dateTransform),
            })
            .partial(),
        resolve: ({ ctx, input: { start, end } }) => {
            return ctx.accountService.getAccountRollup(ctx.user!.id, start, end)
        },
    })
)

export default router
