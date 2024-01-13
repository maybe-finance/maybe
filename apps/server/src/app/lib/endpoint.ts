import type { IMarketDataService } from '@maybe-finance/server/shared'
import type {
    IAccountQueryService,
    IInstitutionService,
    IInsightService,
    ISecurityPricingService,
    IPlanService,
    IEmailService,
} from '@maybe-finance/server/features'
import {
    CryptoService,
    EndpointFactory,
    QueueService,
    PgService,
    PolygonMarketDataService,
    CacheService,
    ServerUtil,
    RedisCacheBackend,
    BullQueueFactory,
    InMemoryQueueFactory,
} from '@maybe-finance/server/shared'
import type { Request } from 'express'
import Redis from 'ioredis'
import {
    AccountService,
    AccountConnectionService,
    AuthUserService,
    UserService,
    EmailService,
    AccountQueryService,
    ValuationService,
    InstitutionService,
    PlaidService,
    AccountConnectionProviderFactory,
    BalanceSyncStrategyFactory,
    ValuationBalanceSyncStrategy,
    TransactionBalanceSyncStrategy,
    InvestmentTransactionBalanceSyncStrategy,
    PlaidETL,
    FinicityService,
    FinicityETL,
    InstitutionProviderFactory,
    FinicityWebhookHandler,
    PlaidWebhookHandler,
    InsightService,
    SecurityPricingService,
    TransactionService,
    HoldingService,
    LoanBalanceSyncStrategy,
    PlanService,
    ProjectionCalculator,
    StripeWebhookHandler,
} from '@maybe-finance/server/features'
import { SharedType } from '@maybe-finance/shared'
import prisma from './prisma'
import plaid, { getPlaidWebhookUrl } from './plaid'
import finicity, { getFinicityTxPushUrl, getFinicityWebhookUrl } from './finicity'
import stripe from './stripe'
import postmark from './postmark'
import { managementClient } from './auth0'
import defineAbilityFor from './ability'
import env from '../../env'
import logger from '../lib/logger'

// shared services

const redis = new Redis(env.NX_REDIS_URL, {
    retryStrategy: ServerUtil.redisRetryStrategy({ maxAttempts: 5 }),
})

export const queueService = new QueueService(
    logger.child({ service: 'QueueService' }),
    process.env.NODE_ENV === 'test'
        ? new InMemoryQueueFactory()
        : new BullQueueFactory(logger.child({ service: 'BullQueueFactory' }), env.NX_REDIS_URL)
)

export const emailService: IEmailService = new EmailService(
    logger.child({ service: 'EmailService' }),
    postmark,
    {
        from: env.NX_POSTMARK_FROM_ADDRESS,
        replyTo: env.NX_POSTMARK_REPLY_TO_ADDRESS,
    }
)

const cryptoService = new CryptoService(env.NX_DATABASE_SECRET)

const pgService = new PgService(logger.child({ service: 'PgService' }), env.NX_DATABASE_URL)

const cacheService = new CacheService(
    logger.child({ service: 'CacheService' }),
    new RedisCacheBackend(redis)
)

const marketDataService: IMarketDataService = new PolygonMarketDataService(
    logger.child({ service: 'PolygonMarketDataService' }),
    env.NX_POLYGON_API_KEY,
    cacheService
)

const securityPricingService: ISecurityPricingService = new SecurityPricingService(
    logger.child({ service: 'SecurityPricingService' }),
    prisma,
    marketDataService
)

const insightService: IInsightService = new InsightService(
    logger.child({ service: 'InsightService' }),
    prisma
)

const planService: IPlanService = new PlanService(
    prisma,
    new ProjectionCalculator(),
    insightService
)

// providers

const plaidService = new PlaidService(
    logger.child({ service: 'PlaidService' }),
    prisma,
    plaid,
    new PlaidETL(
        logger.child({ service: 'PlaidETL' }),
        prisma,
        plaid,
        cryptoService,
        marketDataService
    ),
    cryptoService,
    getPlaidWebhookUrl(),
    env.NX_CLIENT_URL_CUSTOM || env.NX_CLIENT_URL
)

const finicityService = new FinicityService(
    logger.child({ service: 'FinicityService' }),
    prisma,
    finicity,
    new FinicityETL(logger.child({ service: 'FinicityETL' }), prisma, finicity),
    getFinicityWebhookUrl(),
    env.NX_FINICITY_ENV === 'sandbox'
)

// account-connection

const accountConnectionProviderFactory = new AccountConnectionProviderFactory({
    plaid: plaidService,
    finicity: finicityService,
})

const transactionStrategy = new TransactionBalanceSyncStrategy(
    logger.child({ service: 'TransactionBalanceSyncStrategy' }),
    prisma
)

const investmentTransactionStrategy = new InvestmentTransactionBalanceSyncStrategy(
    logger.child({ service: 'InvestmentTransactionBalanceSyncStrategy' }),
    prisma
)

const valuationStrategy = new ValuationBalanceSyncStrategy(
    logger.child({ service: 'ValuationBalanceSyncStrategy' }),
    prisma
)

const loanStrategy = new LoanBalanceSyncStrategy(
    logger.child({ service: 'LoanBalanceSyncStrategy' }),
    prisma
)

const balanceSyncStrategyFactory = new BalanceSyncStrategyFactory({
    INVESTMENT: investmentTransactionStrategy,
    DEPOSITORY: transactionStrategy,
    CREDIT: transactionStrategy,
    LOAN: loanStrategy,
    PROPERTY: valuationStrategy,
    VEHICLE: valuationStrategy,
    OTHER_ASSET: valuationStrategy,
    OTHER_LIABILITY: valuationStrategy,
})

const accountConnectionService = new AccountConnectionService(
    logger.child({ service: 'AccountConnectionService' }),
    prisma,
    accountConnectionProviderFactory,
    balanceSyncStrategyFactory,
    securityPricingService,
    queueService.getQueue('sync-account-connection')
)

// account

const accountQueryService: IAccountQueryService = new AccountQueryService(
    logger.child({ service: 'AccountQueryService' }),
    pgService
)

const accountService = new AccountService(
    logger.child({ service: 'AccountService' }),
    prisma,
    accountQueryService,
    queueService.getQueue('sync-account'),
    queueService.getQueue('sync-account-connection'),
    balanceSyncStrategyFactory
)

// auth-user

const authUserService = new AuthUserService(logger.child({ service: 'AuthUserService' }), prisma)

// user

const userService = new UserService(
    logger.child({ service: 'UserService' }),
    prisma,
    accountQueryService,
    balanceSyncStrategyFactory,
    queueService.getQueue('sync-user'),
    queueService.getQueue('purge-user'),
    managementClient,
    stripe
)

// institution

const institutionProviderFactory = new InstitutionProviderFactory({
    PLAID: plaidService,
    FINICITY: finicityService,
})

const institutionService: IInstitutionService = new InstitutionService(
    logger.child({ service: 'InstitutionService' }),
    prisma,
    pgService,
    institutionProviderFactory
)

// valuation

const valuationService = new ValuationService(
    logger.child({ service: 'ValuationService' }),
    prisma,
    accountQueryService
)

// transaction

const transactionService = new TransactionService(
    logger.child({ service: 'TransactionService' }),
    prisma
)

// holding

const holdingService = new HoldingService(logger.child({ service: 'HoldingService' }), prisma)

// webhooks

const plaidWebhooks = new PlaidWebhookHandler(
    logger.child({ service: 'PlaidWebhookHandler' }),
    prisma,
    plaid,
    accountConnectionService,
    queueService
)

const finicityWebhooks = new FinicityWebhookHandler(
    logger.child({ service: 'FinicityWebhookHandler' }),
    prisma,
    finicity,
    accountConnectionService,
    getFinicityTxPushUrl()
)

const stripeWebhooks = new StripeWebhookHandler(
    logger.child({ service: 'StripeWebhookHandler' }),
    prisma,
    stripe
)

// helper function for parsing JWT and loading User record
// TODO: update this with roles, identity, and metadata
async function getCurrentUser(jwt: NonNullable<Request['user']>) {
    if (!jwt.sub) throw new Error(`jwt missing sub`)
    if (!jwt['https://maybe.co/email']) throw new Error(`jwt missing email`)

    const user =
        (await prisma.user.findUnique({
            where: { authId: jwt.sub },
        })) ??
        (await prisma.user.upsert({
            where: { authId: jwt.sub },
            create: {
                authId: jwt.sub,
                email: jwt['https://maybe.co/email'],
                picture: jwt['picture'],
                firstName: jwt['firstName'],
                lastName: jwt['lastName'],
            },
            update: {},
        }))

    return {
        ...user,
        roles: jwt[SharedType.Auth0CustomNamespace.Roles] ?? [],
        primaryIdentity: jwt[SharedType.Auth0CustomNamespace.PrimaryIdentity] ?? {},
        userMetadata: jwt[SharedType.Auth0CustomNamespace.UserMetadata] ?? {},
        appMetadata: jwt[SharedType.Auth0CustomNamespace.AppMetadata] ?? {},
    }
}

export async function createContext(req: Request) {
    const user = req.user ? await getCurrentUser(req.user) : null

    return {
        prisma,
        plaid,
        stripe,
        managementClient,
        logger,
        user,
        ability: defineAbilityFor(user),
        accountService,
        transactionService,
        holdingService,
        accountConnectionService,
        authUserService,
        userService,
        valuationService,
        institutionService,
        cryptoService,
        queueService,
        plaidService,
        plaidWebhooks,
        finicityService,
        finicityWebhooks,
        stripeWebhooks,
        insightService,
        marketDataService,
        planService,
        emailService,
    }
}

export default new EndpointFactory({
    createContext,
    onSuccess: (req, res, data) => res.status(200).superjson(data),
})
