import { z } from 'zod'
import { Router } from 'express'
import endpoint from '../lib/endpoint'

const router = Router()

router.post(
    '/connect-url',
    endpoint.create({
        input: z.object({
            institutionId: z.string(),
        }),
        resolve: async ({ ctx, input }) => {
            return await ctx.finicityService.generateConnectUrl(ctx.user!.id, input.institutionId)
        },
    })
)

router.post(
    '/institutions/sync',
    endpoint.create({
        resolve: async ({ ctx }) => {
            ctx.ability.throwUnlessCan('manage', 'Institution')
            await ctx.queueService
                .getQueue('sync-institution')
                .add('sync-finicity-institutions', {})
        },
    })
)

export default router
