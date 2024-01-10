import type { RequestHandler } from 'express'
import type { SharedType } from '@maybe-finance/shared'
import { superjson as sj } from '@maybe-finance/shared'

export const superjson: RequestHandler = (req, res, next) => {
    // Client *should* make requests with valid superjson format, { json: any, meta?: any }
    if ('json' in req.body) {
        req.body = sj.deserialize(req.body)
    }

    const _json = res.json.bind(res)
    res.superjson = (data) => {
        const serialized = sj.serialize(data)
        const responsePayload: SharedType.SuccessResponse = { data: serialized }
        return _json(responsePayload)
    }

    next()
}
