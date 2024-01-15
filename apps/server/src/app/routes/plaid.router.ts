import { Router } from 'express'
import { z } from 'zod'
import endpoint from '../lib/endpoint'
import axios from 'axios'
import { devOnly } from '../middleware'

const router = Router()

/**
 * @swagger
 * tags:
 *   name: Plaid
 *   description: Plaid
 */

/**
 * @swagger
 * /status:
 *   get:
 *     description: Returns status
 *     tags:
 *      - Plaid
 *     produces:
 *      - application/json
 *     responses:
 *       200:
 *         description: users
 */
router.get(
    '/status',
    endpoint.create({
        resolve: async () => {
            const { data } = await axios.get('https://status.plaid.com/api/v2/status.json')
            return data
        },
    })
)

/**
 * Get link token for OAuth re-initialization
 *
 * @see https://plaid.com/docs/link/oauth/#reinitializing-link
 */
router.get(
    '/link-token',
    endpoint.create({
        resolve: async ({ ctx }) => {
            const token = await ctx.plaidService.getLinkToken(ctx.user!.id)
            return { token }
        },
    })
)

router.post(
    '/link-token',
    endpoint.create({
        input: z.object({
            institutionId: z.string().optional(),
        }),
        resolve: async ({ ctx }) => {
            // Step 1: Create a Link token for the client to use
            // https://plaid.com/docs/api/tokens/#linktokencreate
            const token = await ctx.plaidService.createLinkToken(ctx.user!.id)

            await ctx.plaidService.cacheLinkToken(ctx.user!.id, token)

            return { token }
        },
    })
)

router.post(
    '/exchange-public-token',
    endpoint.create({
        input: z.object({
            token: z.string(),
            institution: z.object({
                name: z.string(),
                institution_id: z.string(),
            }),
        }),
        resolve: ({ input: { token, institution }, ctx }) => {
            // Step 2: Exchange public token provided to the client for a permanent access token
            // https://plaid.com/docs/api/tokens/#itempublic_tokenexchange
            return ctx.plaidService.exchangePublicToken(ctx.user!.id, token, institution)
        },
    })
)

router.post(
    '/sandbox/quick-add',
    devOnly,
    endpoint.create({
        input: z.object({ username: z.string().optional() }),
        resolve: async ({ ctx, input: { username } }) => {
            return ctx.plaidService.createSandboxAccount(ctx.user!.id, username)
        },
    })
)

router.post(
    '/institutions/sync',
    endpoint.create({
        resolve: async ({ ctx }) => {
            ctx.ability.throwUnlessCan('manage', 'Institution')
            await ctx.queueService.getQueue('sync-institution').add('sync-plaid-institutions', {})
        },
    })
)

export default router
