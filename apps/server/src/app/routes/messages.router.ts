import { Router } from 'express'
import { subject } from '@casl/ability'
import { MessageUpdateSchema } from '@maybe-finance/server/features'
import endpoint from '../lib/endpoint'

const router = Router()

router.patch(
    '/:id',
    endpoint.create({
        input: MessageUpdateSchema,
        async resolve({ ctx, req, input }) {
            const message = await ctx.messageService.get(+req.params.id)
            ctx.ability.throwUnlessCan('update', subject('Message', message))
            return ctx.messageService.update(message.id, input)
        },
    })
)

router.delete(
    '/:id',
    endpoint.create({
        async resolve({ ctx, req }) {
            const message = await ctx.messageService.get(+req.params.id)
            ctx.ability.throwUnlessCan('delete', subject('Message', message))
            return ctx.messageService.delete(message.id)
        },
    })
)

export default router
