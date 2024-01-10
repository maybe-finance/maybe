import type { ErrorRequestHandler } from 'express'
import { ForbiddenError } from '@casl/ability'

export const authErrorHandler: ErrorRequestHandler = (err, req, res, next) => {
    if (err instanceof ForbiddenError) {
        return res.status(403).json({
            errors: [
                {
                    status: '403',
                    title: 'Unauthorized',
                    detail: err.message,
                },
            ],
        })
    }

    next(err)
}
