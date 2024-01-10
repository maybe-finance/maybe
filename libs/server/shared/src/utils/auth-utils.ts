import jwks from 'jwks-rsa'
import jwt from 'jsonwebtoken'
import { SharedType } from '@maybe-finance/shared'

export const verifyRoleClaims = (claims, role: SharedType.UserRole) => {
    const customRoleClaim = claims[SharedType.Auth0CustomNamespace.Roles]

    return customRoleClaim && Array.isArray(customRoleClaim) && customRoleClaim.includes(role)
}

export async function validateRS256JWT(
    token: string,
    domain: string,
    audience: string
): Promise<{
    auth0Id: string
    userMetadata: SharedType.MaybeUserMetadata
    appMetadata: SharedType.MaybeAppMetadata
}> {
    const jwksClient = jwks({
        rateLimit: true,
        jwksUri: `https://${domain}/.well-known/jwks.json`,
    })

    return new Promise((resolve, reject) => {
        if (!token) reject('No token provided')

        const parts = token.split(' ')

        if (!parts || parts.length !== 2) reject('JWT must be in format: Bearer <token>')
        if (parts[0] !== 'Bearer') reject('JWT must be in format: Bearer <token>')

        const rawToken = parts[1]

        jwt.verify(
            rawToken,
            (header, cb) => {
                jwksClient
                    .getSigningKey(header.kid)
                    .then((key) => cb(null, key.getPublicKey()))
                    .catch((err) => cb(err))
            },
            {
                audience,
                issuer: `https://${domain}/`,
                algorithms: ['RS256'],
            },
            (err, payload) => {
                if (err) return reject(err)
                if (typeof payload !== 'object') return reject('payload not an object')

                resolve({
                    auth0Id: payload.sub!,
                    appMetadata: payload[SharedType.Auth0CustomNamespace.AppMetadata] ?? {},
                    userMetadata: payload[SharedType.Auth0CustomNamespace.UserMetadata] ?? {},
                })
            }
        )
    })
}
