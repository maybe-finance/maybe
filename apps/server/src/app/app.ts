import type { RequestHandler } from 'express'
import express from 'express'
import cors from 'cors'
import morgan from 'morgan'
import * as Sentry from '@sentry/node'
import * as SentryTracing from '@sentry/tracing'
import * as trpcExpress from '@trpc/server/adapters/express'
import { appRouter, createTRPCContext } from './trpc'
import { apiReference } from '@scalar/express-api-reference'
import swaggerJsdoc from 'swagger-jsdoc'

/**
 * In Express 4.x, asynchronous errors are NOT automatically passed to next().  This middleware is a small
 * wrapper around Express that enables automatic async error handling
 *
 * Benefit: Eliminates the need for try / catch blocks in routes (i.e. `next(err)` will automatically be called on failed Promise)
 *
 * When stable Express 5.x is released, this won't be necessary - https://github.com/expressjs/express/issues/4543#issuecomment-789256044
 */
import 'express-async-errors'
import logger from './lib/logger'
import prisma from './lib/prisma'
import {
    defaultErrorHandler,
    validateAuthJwt,
    superjson,
    authErrorHandler,
    maintenance,
    identifySentryUser,
    devOnly,
} from './middleware'
import {
    usersRouter,
    accountsRouter,
    connectionsRouter,
    webhooksRouter,
    plaidRouter,
    accountRollupRouter,
    valuationsRouter,
    institutionsRouter,
    finicityRouter,
    transactionsRouter,
    holdingsRouter,
    securitiesRouter,
    plansRouter,
    toolsRouter,
    publicRouter,
    e2eRouter,
} from './routes'
import env from '../env'
import maybeScalarTheme from './maybe-scalar-theme'

const app = express()

// put health check before maintenance and other middleware
app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'OK' })
})

if (process.env.NODE_ENV !== 'test') {
    maintenance(app)
}

// Mostly defaults recommended by quickstart
// - https://docs.sentry.io/platforms/node/guides/express/
// - https://docs.sentry.io/platforms/node/guides/express/performance/
Sentry.init({
    dsn: env.NX_SENTRY_DSN,
    environment: env.NX_SENTRY_ENV,
    maxValueLength: 8196,
    integrations: [
        new Sentry.Integrations.Http({ tracing: true }),
        new SentryTracing.Integrations.Express({ app }),
        new SentryTracing.Integrations.Postgres(),
        new SentryTracing.Integrations.Prisma({ client: prisma }),
    ],
    tracesSampler: (ctx) => {
        return ctx.request?.method === 'OPTIONS' ? false : ctx.parentSampled ?? true
    },
})

app.use(Sentry.Handlers.requestHandler())
app.use(Sentry.Handlers.tracingHandler())

app.get('/', (req, res) => {
    res.render('pages/index', { error: req.query.error })
})

// Only Auth0 users with a role of "admin" can view these pages (i.e. Maybe Employees)
app.use(express.static(__dirname + '/assets'))

const origin = [env.NX_CLIENT_URL, ...env.NX_CORS_ORIGINS]
logger.info(`CORS origins: ${origin}`)
app.use(cors({ origin, credentials: true }))
app.options('*', cors() as RequestHandler)

app.set('view engine', 'ejs').set('views', __dirname + '/app/admin/views')

app.use(
    morgan(env.NX_MORGAN_LOG_LEVEL, {
        stream: {
            write: function (message: string) {
                logger.http(message.trim()) // Trim because Morgan and Logger both add \n, so avoid duplicates here
            },
        },
    })
)

// Stripe webhooks require a raw request body
app.use('/v1/stripe', express.raw({ type: 'application/json' }))

app.use(express.urlencoded({ extended: true }))
app.use(express.json({ limit: '50mb' })) // Finicity sends large response bodies for webhooks

// =========================================
//                 API ⬇️
// =========================================

app.use(
    '/trpc',
    validateAuthJwt,
    trpcExpress.createExpressMiddleware({
        router: appRouter,
        createContext: createTRPCContext,
    })
)

/**
 * This intercepts the express.json() middleware and modifies both the outgoing and incoming requests
 *
 * It is necessary because our models use Date, BigInt, and other non serializable JSON types
 *
 * Outgoing requests are serialized, and will be in the format { data: { json, meta }, ...rest }
 * Incoming requests are deserialized (client sends a serialized object { json, meta }), and attached to req.body
 */
app.use(superjson)

// Public routes
// Keep this route public for Render health checks - https://render.com/docs/deploys#health-checks
app.get('/v1', (_req, res) => {
    res.status(200).json({ msg: 'API Running' })
})

app.get('/debug-sentry', function mainHandler(_req, _res) {
    throw new Error('Server sentry is working correctly')
})

app.use('/tools', devOnly, toolsRouter)

app.use('/v1', webhooksRouter)

app.use('/v1', publicRouter)

// All routes AFTER this line are protected via OAuth
app.use('/v1', validateAuthJwt)

// Private routes
app.use('/v1/users', usersRouter)
app.use('/v1/e2e', e2eRouter)
app.use('/v1/plaid', plaidRouter)
app.use('/v1/finicity', finicityRouter)
app.use('/v1/accounts', accountsRouter)
app.use('/v1/account-rollup', accountRollupRouter)
app.use('/v1/connections', connectionsRouter)
app.use('/v1/valuations', valuationsRouter)
app.use('/v1/institutions', institutionsRouter)
app.use('/v1/transactions', transactionsRouter)
app.use('/v1/holdings', holdingsRouter)
app.use('/v1/securities', securitiesRouter)
app.use('/v1/plans', plansRouter)

// api docs
const options = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'Maybe API References',
            description:
                'This page may not represent the current state of the API and is primarily here as a quick reference to see everything in one spot.',
            version: '1.0.0',
        },
    },
    apis: ['**/routes/**.router.ts'],
}

const openapiSpecification = swaggerJsdoc(options)

app.use(
    '/reference',
    apiReference({
        customCss: maybeScalarTheme,
        spec: {
            content: openapiSpecification,
        },
    })
)

// Sentry must be the *first* handler
app.use(identifySentryUser)
app.use(Sentry.Handlers.errorHandler())

// Errors will pass through in order listed, these MUST be at the bottom of this server file
app.use(authErrorHandler) // Handles auth/authz specific errors
app.use(defaultErrorHandler) // Fallback handler

export default app
