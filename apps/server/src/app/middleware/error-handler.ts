import type { ErrorRequestHandler } from 'express'
import type { SharedType } from '@maybe-finance/shared'
import logger from '../lib/logger'
import { ErrorUtil } from '@maybe-finance/server/shared'

export const defaultErrorHandler: ErrorRequestHandler = async (err, req, res, _next) => {
    const parsedError = ErrorUtil.parseError(err)

    // A custom redirect if user tries to access admin dashboard without Admin role (see /apps/server/src/app/admin/admin-router.ts)
    if (parsedError.message === 'ADMIN_UNAUTHORIZED') {
        return res.redirect('/?error=invalid-credentials')
    }

    const errors: SharedType.ErrorResponse = {
        errors: [
            {
                status: parsedError.statusCode || '500',
                title: parsedError.message,
            },
        ],
    }

    logger.error(`[default-express-handler] ${parsedError.message}`, {
        metadata: parsedError.metadata,
        stackTrace: parsedError.stackTrace,
        user: req.user?.sub,
        request: {
            method: req.method,
            url: req.url,
        },
    })

    logger.debug(parsedError.stackTrace)

    res.status(+(parsedError.statusCode || 500)).json(errors)
}
