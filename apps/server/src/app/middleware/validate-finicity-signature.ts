import type { RequestHandler } from 'express'
import crypto from 'crypto'
import env from '../../env'

/**
 * middleware to validate the `x-finicity-signature` header
 *
 * https://docs.finicity.com/connect-and-mvs-webhooks/
 */
export const validateFinicitySignature: RequestHandler = (req, res, next) => {
    const signature = crypto
        .createHmac('sha256', env.NX_FINICITY_PARTNER_SECRET)
        .update(JSON.stringify(req.body))
        .digest('hex')

    if (req.get('x-finicity-signature') !== signature) {
        throw new Error('invalid finicity signature')
    }

    next()
}
