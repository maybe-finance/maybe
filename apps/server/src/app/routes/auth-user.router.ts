import { Router } from 'express'
import { z } from 'zod'
import endpoint from '../lib/endpoint'

const router = Router()

router.get(
    '/',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const email = req.query.email
            const user = await ctx.authUserService.getByEmail(email as string)
            if (user) return user
            return null
        },
    })
)

router.post(
    '/',
    endpoint.create({
        input: z.object({
            name: z.string(),
            email: z.string().email(),
            password: z.string().min(6),
        }),
        resolve: async ({ input, ctx }) => {
            return await ctx.authUserService.create({
                name: input.name,
                email: input.email,
                password: input.password,
            })
        },
    })
)

export default router
