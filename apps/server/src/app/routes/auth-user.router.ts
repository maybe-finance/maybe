import { Router } from 'express'
import { z } from 'zod'
import endpoint from '../lib/endpoint'

const router = Router()

router.get(
    '/',
    endpoint.create({
        resolve: async ({ ctx, req }) => {
            const email = req.query.email
            console.log('Going to get the user for email', email)
            const user = await ctx.authUserService.getByEmail(email as string)
            console.log('Got the user', user)
            if (user) return user
            console.log('No user found')
            return { data: null }
        },
    })
)

router.post(
    '/',
    endpoint.create({
        input: z.object({
            email: z.string().email(),
            password: z.string().min(6),
        }),
        resolve: async ({ input, ctx }) => {
            return await ctx.authUserService.create({
                email: input.email,
                password: input.password,
            })
        },
    })
)

export default router
