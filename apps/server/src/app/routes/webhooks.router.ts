import { Router } from 'express'
import { z } from 'zod'
import { validateTellerSignature } from '../middleware'
import endpoint from '../lib/endpoint'
import stripe from '../lib/stripe'
import env from '../../env'
import type { TellerTypes } from '@maybe-finance/teller-api'

const router = Router()

router.post(
    '/stripe/webhook',
    endpoint.create({
        async resolve({ req, ctx }) {
            if (!req.headers['stripe-signature'])
                throw new Error('Missing `stripe-signature` header')

            let event
            try {
                event = stripe.webhooks.constructEvent(
                    req.body,
                    req.headers['stripe-signature'],
                    env.NX_STRIPE_WEBHOOK_SECRET
                )
            } catch (err) {
                ctx.logger.error(`Failed to construct Stripe event`, err)
                throw new Error('Failed to construct Stripe event')
            }

            ctx.logger.info(`rx[stripe_webhook] type=${event.type} id=${event.id}`, event.data)

            await ctx.stripeWebhooks.handleWebhook(event)

            return { status: 'ok' }
        },
        onSuccess: (_, res, data) => res.status(200).json(data),
    })
)

router.post(
    '/teller/webhook',
    process.env.NODE_ENV !== 'development' ? validateTellerSignature : (_req, _res, next) => next(),
    endpoint.create({
        input: z
            .object({
                id: z.string(),
                payload: z.object({
                    enrollment_id: z.string(),
                    reason: z.string(),
                }),
                timestamp: z.string(),
                type: z.string(),
            })
            .passthrough(),
        async resolve({ input, ctx }) {
            const { type, id, payload } = input

            ctx.logger.info(
                `rx[teller_webhook] event eventType=${type} eventId=${id} enrollmentId=${payload.enrollment_id}`
            )

            // May contain sensitive info, only print at the debug level
            ctx.logger.debug(`rx[teller_webhook] event payload`, input)

            try {
                console.log('handling webhook')
                await ctx.tellerWebhooks.handleWebhook(input as TellerTypes.WebhookData)
            } catch (err) {
                // record error but don't throw
                ctx.logger.error(`[teller_webhook] error handling webhook`, err)
            }

            return { status: 'ok' }
        },
    })
)

export default router
