import express, { Send, Response, Request } from 'express'
import { SharedType } from '@maybe-finance/shared'

// Because this is a module, need to escape from module scope and enter global scope so declaration merging works correctly
declare global {
    namespace Express {
        interface Request {
            // Add custom properties here (i.e. if props are defined with middleware)
            user?: User & SharedType.MaybeCustomClaims
        }

        interface Response {
            json(data: any): Send<Response, this>
            superjson(data: any): Send<Response, this>
        }

        // express-jwt already adds a `user` prop to `req` object, we just need to define it
        // This is the structure of the Auth0 user object - https://auth0.com/docs/users/user-profiles/user-profile-structure
        // https://github.com/DefinitelyTyped/DefinitelyTyped/blob/96d20a6a47593b83b0331a0a3f163a39aba523aa/types/express-jwt/index.d.ts#L69
        interface User
            extends Partial<{
                iss: string
                sub: string
                aud: string[]
                iat: number
                exp: number
                azp: string
                scope: string
            }> {}
    }
}
