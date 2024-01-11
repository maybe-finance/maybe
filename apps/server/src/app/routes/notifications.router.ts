import { Router } from 'express'
import endpoint from '../lib/endpoint'

const router = Router()

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
