import { Router } from 'express'
import { z } from 'zod'
import endpoint from '../lib/endpoint'

const router = Router()

router.post(
    '/handle-enrollment',
    endpoint.create({
        input: z.object({
            institution: z.object({
                name: z.string(),
                id: z.string(),
            }),
            enrollment: z.object({
                accessToken: z.string(),
                user: z.object({
                    id: z.string(),
                }),
                enrollment: z.object({
                    id: z.string(),
                    institution: z.object({
                        name: z.string(),
                    }),
                }),
                signatures: z.array(z.string()).optional(),
            }),
        }),
        resolve: ({ input: { institution, enrollment }, ctx }) => {
            return ctx.tellerService.handleEnrollment(ctx.user!.id, institution, enrollment)
        },
    })
)

router.post(
    '/institutions/sync',
    endpoint.create({
        resolve: async ({ ctx }) => {
            ctx.ability.throwUnlessCan('manage', 'Institution')
            await ctx.queueService.getQueue('sync-institution').add('sync-teller-institutions', {})
        },
    })
)

export default router
