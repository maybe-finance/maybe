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
    }
}
