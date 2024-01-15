import crypto from 'crypto'
import type { RequestHandler } from 'express'
import type { TellerTypes } from '@maybe-finance/teller-api'
import env from '../../env'

// https://teller.io/docs/api/webhooks#verifying-messages
export const validateTellerSignature: RequestHandler = (req, res, next) => {
    const signatureHeader = req.headers['teller-signature'] as string | undefined

    if (!signatureHeader) {
        return res.status(401).send('No Teller-Signature header found')
    }

    const { timestamp, signatures } = parseTellerSignatureHeader(signatureHeader)
    const threeMinutesAgo = Math.floor(Date.now() / 1000) - 3 * 60

    if (parseInt(timestamp) < threeMinutesAgo) {
        return res.status(408).send('Signature timestamp is too old')
    }

    const signedMessage = `${timestamp}.${JSON.stringify(req.body as TellerTypes.WebhookData)}`
    const expectedSignature = createHmacSha256(signedMessage, env.NX_TELLER_SIGNING_SECRET)

    if (!signatures.includes(expectedSignature)) {
        return res.status(401).send('Invalid webhook signature')
    }

    next()
}

const parseTellerSignatureHeader = (
    header: string
): { timestamp: string; signatures: string[] } => {
    const parts = header.split(',')
    const timestampPart = parts.find((p) => p.startsWith('t='))
    const signatureParts = parts.filter((p) => p.startsWith('v1='))

    if (!timestampPart) {
        throw new Error('No timestamp in Teller-Signature header')
    }

    const timestamp = timestampPart.split('=')[1]
    const signatures = signatureParts.map((p) => p.split('=')[1])

    return { timestamp, signatures }
}

const createHmacSha256 = (message: string, secret: string): string => {
    return crypto.createHmac('sha256', secret).update(message).digest('hex')
}
