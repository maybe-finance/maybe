import { Router } from 'express'
import { z } from 'zod'
import endpoint from '../lib/endpoint'

const router = Router()

router.put(
    '/ask-the-advisor',
    endpoint.create({
        input: z
            .object({
                ataAll: z.boolean(),
                ataSubmitted: z.boolean(),
                ataReview: z.boolean(),
                ataUpdate: z.boolean(),
                ataClosed: z.boolean(),
                ataExpire: z.boolean(),
            })
            .partial(),
        resolve: async ({ ctx, input }) => {
            return ctx.prisma.user.update({
                where: { id: ctx.user!.id },
                data: input,
            })
        },
    })
)

router.get(
    '/convertkit/subscription',
    endpoint.create({
        resolve: async ({ ctx }) => {
            return ctx.convertKit.getSubscription(ctx.user!.convertKitId)
        },
    })
)

router.post(
    '/convertkit/subscribe',
    endpoint.create({
        resolve: async ({ ctx }) => {
            const auth0User = await ctx.managementClient.getUser({ id: ctx.user!.auth0Id })

            const { subscription } = await ctx.convertKit.subscribe(auth0User.email!)

            await ctx.userService.update(ctx.user!.id, {
                convertKitId: subscription.subscriber.id,
            })

            return subscription
        },
    })
)

router.post(
    '/convertkit/unsubscribe',
    endpoint.create({
        resolve: async ({ ctx }) => {
            const auth0User = await ctx.managementClient.getUser({ id: ctx.user!.auth0Id })
            const { subscriber } = await ctx.convertKit.unsubscribe(auth0User.email!)
            return subscriber
        },
    })
)

export default router
