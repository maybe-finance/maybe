import { Router } from 'express'
import { z } from 'zod'
import { DateUtil } from '@maybe-finance/shared'
import endpoint from '../lib/endpoint'

const router = Router()

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
