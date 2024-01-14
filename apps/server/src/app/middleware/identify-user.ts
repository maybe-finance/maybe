import type { ErrorRequestHandler } from 'express'
import * as Sentry from '@sentry/node'

export const identifySentryUser: ErrorRequestHandler = (err, req, _res, next) => {
    Sentry.setUser({
        authId: req.user?.sub,
    })

    next(err)
}
