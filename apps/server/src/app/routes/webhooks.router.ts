import { Router } from 'express'
import { z } from 'zod'
import type { FinicityTypes } from '@maybe-finance/finicity-api'
import { validatePlaidJwt, validateFinicitySignature } from '../middleware'
import endpoint from '../lib/endpoint'
import stripe from '../lib/stripe'
import env from '../../env'

const router = Router()

/**
 * @swagger
 * tags:
 *   name: Webhooks
 *   description: Webhooks
 */

/**
 * @swagger
 * /plaid/webhook:
 *   get:
 *     description: Webhook for plaid
 *     tags:
 *      - Webhooks
 *     produces:
 *      - application/json
 *     responses:
 *       200:
 *         description: users
 */
router.post(
    '/plaid/webhook',
    process.env.NODE_ENV !== 'development' ? validatePlaidJwt : (_req, _res, next) => next(),
    endpoint.create({
        input: z
            .object({
                webhook_type: z.string(),
                webhook_code: z.string(),
                item_id: z.string(),
            })
            .passthrough(),
        async resolve({ input, ctx }) {
            const { webhook_type, webhook_code, item_id, ...data } = input

            ctx.logger.info(
                `rx[plaid_webhook] type=${webhook_type} code=${webhook_code} item=${item_id}`,
                data
            )

            await ctx.plaidWebhooks.handleWebhook(input)

            return { status: 'ok' }
        },
    })
)

router.post(
    '/finicity/webhook',
    process.env.NODE_ENV !== 'development'
        ? validateFinicitySignature
        : (_req, _res, next) => next(),
    endpoint.create({
        input: z
            .object({
                eventType: z.string(),
                eventId: z.string().optional(),
                customerId: z.string().optional(),
                payload: z.record(z.any()).optional(),
            })
            .passthrough(),
        async resolve({ input, ctx }) {
            const { eventType, eventId, customerId } = input

            ctx.logger.info(
                `rx[finicity_webhook] event eventType=${eventType} eventId=${eventId} customerId=${customerId}`
            )

            // May contain sensitive info, only print at the debug level
            ctx.logger.debug(`rx[finicity_webhook] event payload`, input)

            try {
                await ctx.finicityWebhooks.handleWebhook(input as FinicityTypes.WebhookData)
            } catch (err) {
                // record error but don't throw, otherwise Finicity Connect behaves weird
                ctx.logger.error(`[finicity_webhook] error handling webhook`, err)
            }

            return { status: 'ok' }
        },
    })
)

router.get('/finicity/txpush', (req, res) => {
    const { txpush_verification_code } = req.query
    if (!txpush_verification_code) {
        return res.status(400).send('request missing txpush_verification_code')
    }

    return res.status(200).contentType('text/plain').send(txpush_verification_code)
})

router.post(
    '/finicity/txpush',
    endpoint.create({
        input: z
            .object({
                event: z.record(z.any()), // for now we'll just cast this to the appropriate type
            })
            .passthrough(),
        async resolve({ input: { event }, ctx }) {
            const ev = event as FinicityTypes.TxPushEvent

            ctx.logger.info(`rx[finicity_txpush] event class=${ev.class} type=${ev.type}`)

            // May contain sensitive info, only print at the debug level
            ctx.logger.debug(`rx[finicity_txpush] event payload`, event)

            await ctx.finicityWebhooks.handleTxPushEvent(ev)

            return { status: 'ok' }
        },
    })
)

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

export default router
