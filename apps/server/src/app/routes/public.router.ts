import { Router } from 'express'
import { z } from 'zod'
import env from '../../env'
import endpoint from '../lib/endpoint'

const router = Router()

router.get(
    '/users/card/:memberId',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const memberId = req.params.memberId
            if (!memberId) throw new Error('No memberId provided for member details.')

            const clientUrl = env.NX_CLIENT_URL_CUSTOM || env.NX_CLIENT_URL

            return ctx.userService.getMemberCard(memberId, clientUrl)
        },
    })
)

router.post(
    '/request-new-password',
    endpoint.create({
        input: z.object({
            email: z.string().email(),
        }),
        resolve: async ({ ctx, input }) => {
            if (ctx.user) return
            await ctx.authPasswordResetService.create(input.email)
        },
    })
)

router.post(
    '/reset-password/:token/:email',
    endpoint.create({
        input: z.object({
            // TODO: bring en par with required password schema
            // (1 lowercase, 1 uppercase, 1 special char)
            newPassword: z.string().min(8).max(64),
            confirmPassword: z.string().min(8).max(64),
        }),
        resolve: async ({ ctx, input, req }) => {
            if (ctx.user) return
            await ctx.authPasswordResetService.resetPassword({
                token: req.params.token,
                newPassword: input.newPassword,
                email: req.params.email,
            })
        },
    })
)

export default router
