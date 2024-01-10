import createError from 'http-errors'

export const devOnly = (_req, _res, next) => {
    if (process.env.NODE_ENV !== 'development') {
        return next(createError(401, 'Route only available in dev mode'))
    }

    next()
}
