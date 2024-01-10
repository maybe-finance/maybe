import type { GetVerificationKey } from 'express-jwt'
import { expressjwt as jwt } from 'express-jwt'
import jwks from 'jwks-rsa'
import env from '../../env'

/**
 * The user will authenticate on the frontend SPA (React) via Authorization Code Flow with PKCE
 * and receive an access token.  This token is passed in HTTP headers and validated on the backend
 * via this middleware
 */
export const validateAuth0Jwt = jwt({
    requestProperty: 'user',
    secret: jwks.expressJwtSecret({
        cache: true,
        rateLimit: true,
        jwksRequestsPerMinute: 5,
        jwksUri: `https://${env.NX_AUTH0_CUSTOM_DOMAIN}/.well-known/jwks.json`,
    }) as GetVerificationKey,
    audience: env.NX_AUTH0_AUDIENCE, // This is a unique identifier from Auth0 (not a valid URL)
    issuer: `https://${env.NX_AUTH0_CUSTOM_DOMAIN}/`,
    algorithms: ['RS256'],
})
