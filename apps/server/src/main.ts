import type { AddressInfo } from 'net'
import env from './env'
import app from './app/app'
import logger from './app/lib/logger'
import * as Sentry from '@sentry/node'

process.on('uncaughtException', function (error) {
    Sentry.captureException(error)
    logger.error('server: uncaught exception', error)
})

process.on('unhandledRejection', (reason, promise) => {
    Sentry.captureException(reason)
    logger.error(`server: unhandled promise rejection: ${promise}: ${reason}`)
})

const server = app.listen(env.NX_PORT, () => {
    logger.info(`🚀 API listening at http://localhost:${(server.address() as AddressInfo).port}`)
})

// Handle SIGTERM coming from ECS Fargate
process.on('SIGTERM', () => server.close())

server.on('error', (err) => logger.error('Server failed to start from main.ts', err))
