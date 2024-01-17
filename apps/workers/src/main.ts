import express from 'express'
import cors from 'cors'
import * as Sentry from '@sentry/node'
import * as SentryTracing from '@sentry/tracing'
import { BullQueue } from '@maybe-finance/server/shared'
import logger from './app/lib/logger'
import prisma from './app/lib/prisma'
import {
    accountConnectionProcessor,
    accountProcessor,
    institutionService,
    queueService,
    securityPricingProcessor,
    userProcessor,
    emailProcessor,
    workerErrorHandlerService,
} from './app/lib/di'
import env from './env'

// Defaults from quickstart - https://docs.sentry.io/platforms/node/
Sentry.init({
    dsn: env.NX_SENTRY_DSN,
    environment: env.NX_SENTRY_ENV,
    maxValueLength: 8196,
    integrations: [
        new Sentry.Integrations.Http({ tracing: true }),
        new SentryTracing.Integrations.Postgres(),
        new SentryTracing.Integrations.Prisma({ client: prisma }),
    ],
    tracesSampleRate: 1.0,
})

const syncUserQueue = queueService.getQueue('sync-user')
const syncConnectionQueue = queueService.getQueue('sync-account-connection')
const syncAccountQueue = queueService.getQueue('sync-account')
const syncSecurityQueue = queueService.getQueue('sync-security')
const purgeUserQueue = queueService.getQueue('purge-user')
const syncInstitutionQueue = queueService.getQueue('sync-institution')
const sendEmailQueue = queueService.getQueue('send-email')

syncUserQueue.process(
    'sync-user',
    async (job) => {
        await userProcessor.sync(job.data)
    },
    { concurrency: 4 }
)

syncAccountQueue.process(
    'sync-account',
    async (job) => {
        await accountProcessor.sync(job.data)
    },
    { concurrency: 4 }
)

/**
 * sync-account-connection queue
 */
syncConnectionQueue.process(
    'sync-connection',
    async (job) => {
        await accountConnectionProcessor.sync(job.data, async (progress) => {
            try {
                await job.progress(progress)
            } catch (e) {
                logger.warn('Failed to update SYNC_CONNECTION job progress', job.data)
            }
        })
    },
    { concurrency: 4 }
)

/**
 * sync-security queue
 */
syncSecurityQueue.process(
    'sync-all-securities',
    async () => await securityPricingProcessor.syncAll()
)

/**
 * purge-user queue
 */
purgeUserQueue.process(
    'purge-user',
    async (job) => {
        await userProcessor.delete(job.data)
    },
    { concurrency: 4 }
)

/**
 * sync-all-securities queue
 */
// Start repeated job for syncing securities (Bull won't duplicate it as long as the repeat options are the same)
syncSecurityQueue.add(
    'sync-all-securities',
    {},
    {
        repeat: { cron: '*/5 * * * *' }, // Run every 5 minutes
    }
)

/**
 * sync-institution queue
 */
syncInstitutionQueue.process(
    'sync-plaid-institutions',
    async () => await institutionService.sync('PLAID')
)

syncInstitutionQueue.process(
    'sync-finicity-institutions',
    async () => await institutionService.sync('FINICITY')
)

syncInstitutionQueue.process(
    'sync-teller-institutions',
    async () => await institutionService.sync('TELLER')
)

syncInstitutionQueue.add(
    'sync-plaid-institutions',
    {},
    {
        repeat: { cron: '0 */24 * * *' }, // Run every 24 hours
    }
)

syncInstitutionQueue.add(
    'sync-finicity-institutions',
    {},
    {
        repeat: { cron: '0 */24 * * *' }, // Run every 24 hours
    }
)

syncInstitutionQueue.add(
    'sync-teller-institutions',
    {},
    {
        repeat: { cron: '0 0 */1 * *' }, // Run every 24 hours
    }
)

/**
 * send-email queue
 */
sendEmailQueue.process('send-email', async (job) => await emailProcessor.send(job.data))

sendEmailQueue.add(
    'send-email',
    { type: 'trial-reminders' },
    { repeat: { cron: '0 */12 * * *' } } // Run every 12 hours
)

// Fallback - usually triggered by errors not handled (or thrown) within the Bull event handlers (see above)
process.on(
    'uncaughtException',
    async (error) =>
        await workerErrorHandlerService.handleWorkersError({ variant: 'unhandled', error })
)

// Fallback - usually triggered by errors not handled (or thrown) within the Bull event handlers (see above)
process.on(
    'unhandledRejection',
    async (error) =>
        await workerErrorHandlerService.handleWorkersError({ variant: 'unhandled', error })
)

const app = express()

app.use(cors())

// Make sure that at least 1 of the queues is ready and Redis is connected properly
app.get('/health', (_req, res, _next) => {
    syncConnectionQueue
        .isHealthy()
        .then((isHealthy) => {
            if (isHealthy) {
                res.status(200).json({ success: true, message: 'Queue is healthy' })
            } else {
                res.status(500).json({ success: false, message: 'Queue is not healthy' })
            }
        })
        .catch((err) => {
            console.log(err)
            res.status(500).json({ success: false, message: 'Queue health check failed' })
        })
})

const server = app.listen(env.NX_PORT, () => {
    logger.info(`Worker health server started on port ${env.NX_PORT}`)
})

function onShutdown() {
    logger.info('[shutdown.start]')

    server.close()

    // shutdown queues
    Promise.allSettled(
        queueService.allQueues
            .filter((q): q is BullQueue => q instanceof BullQueue)
            .map((q) => q.queue.close())
    ).finally(() => {
        logger.info('[shutdown.complete]')
        process.exit()
    })
}

process.on('SIGINT', onShutdown)
process.on('SIGTERM', onShutdown)
process.on('exit', (code) => logger.info(`[exit] code=${code}`))

logger.info(`🚀 worker started`)
