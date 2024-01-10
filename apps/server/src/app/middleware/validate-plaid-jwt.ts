import { expressjwt as jwt } from 'express-jwt'
import jwtDecode from 'jwt-decode'
import jwkToPem from 'jwk-to-pem'
import plaid from '../lib/plaid'

// https://plaid.com/docs/api/webhooks/webhook-verification/#webhook_verification_keyget
export const validatePlaidJwt = jwt({
    requestProperty: 'plaidAuth', // Will attach the decoded payload to `req.plaidAuth`
    algorithms: ['ES256'],
    getToken(req) {
        // https://plaid.com/docs/api/webhooks/webhook-verification/#extract-the-jwt-header
        return req.headers['plaid-verification'] as string
    },
    async secret(req, token) {
        const { kid } = jwtDecode<{ alg: string; kid: string; typ: string }>(
            req.headers['plaid-verification'] as string,
            { header: true }
        )

        const res = await plaid.webhookVerificationKeyGet({ key_id: kid })

        // Need to convert JSON => PEM in order to use jsonwebtoken lib to verify - https://github.com/auth0/node-jsonwebtoken/issues/43
        return jwkToPem(res.data.key)
    },
})
