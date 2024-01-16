import type {
    IAccountConnectionProcessor,
    IAccountProcessor,
    IAccountQueryService,
    IAccountService,
    ISecurityPricingProcessor,
    IInstitutionService,
    IUserProcessor,
    ISecurityPricingService,
    IUserService,
    IEmailService,
    IEmailProcessor,
} from '@maybe-finance/server/features'
import {
    AccountConnectionProcessor,
    AccountConnectionProviderFactory,
    AccountConnectionService,
    AccountProcessor,
    AccountProviderFactory,
    AccountQueryService,
    AccountService,
    BalanceSyncStrategyFactory,
    FinicityETL,
    FinicityService,
    InstitutionProviderFactory,
    InstitutionService,
    InvestmentTransactionBalanceSyncStrategy,
    LoanBalanceSyncStrategy,
    PlaidETL,
    PlaidService,
    TellerETL,
    TellerService,
    SecurityPricingProcessor,
    SecurityPricingService,
    TransactionBalanceSyncStrategy,
    UserProcessor,
    UserService,
    ValuationBalanceSyncStrategy,
    EmailService,
    EmailProcessor,
    TransactionService,
} from '@maybe-finance/server/features'
import type { IMarketDataService } from '@maybe-finance/server/shared'
import {
    BullQueueFactory,
    CacheService,
    CryptoService,
    InMemoryQueueFactory,
    PgService,
    PolygonMarketDataService,
    QueueService,
    RedisCacheBackend,
    ServerUtil,
} from '@maybe-finance/server/shared'
import Redis from 'ioredis'
import logger from './logger'
import prisma from './prisma'
import plaid from './plaid'
import finicity from './finicity'
import teller from './teller'
import postmark from './postmark'
import stripe from './stripe'
import env from '../../env'
import { BullQueueEventHandler, WorkerErrorHandlerService } from '../services'

// shared services

const redis = new Redis(env.NX_REDIS_URL, {
    retryStrategy: ServerUtil.redisRetryStrategy({ maxAttempts: 5 }),
})

export const cryptoService = new CryptoService(env.NX_DATABASE_SECRET)
export const pgService = new PgService(logger.child({ service: 'PgService' }), env.NX_DATABASE_URL)

export const queueService = new QueueService(
    logger.child({ service: 'QueueService' }),
    process.env.NODE_ENV === 'test'
        ? new InMemoryQueueFactory()
        : new BullQueueFactory(
              logger.child({ service: 'BullQueueFactory' }),
              env.NX_REDIS_URL,
              new BullQueueEventHandler(logger.child({ service: 'BullQueueEventHandler' }), prisma)
          )
)

const cacheService = new CacheService(
    logger.child({ service: 'CacheService' }),
    new RedisCacheBackend(redis)
)

export const marketDataService: IMarketDataService = new PolygonMarketDataService(
    logger.child({ service: 'PolygonMarketDataService' }),
    env.NX_POLYGON_API_KEY,
    cacheService
)

export const securityPricingService: ISecurityPricingService = new SecurityPricingService(
    logger.child({ service: 'SecurityPricingService' }),
    prisma,
    marketDataService
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
    '',
    ''
)

const finicityService = new FinicityService(
    logger.child({ service: 'FinicityService' }),
    prisma,
    finicity,
    new FinicityETL(logger.child({ service: 'FinicityETL' }), prisma, finicity),
    '',
    env.NX_FINICITY_ENV === 'sandbox'
)

const tellerService = new TellerService(
    logger.child({ service: 'TellerService' }),
    prisma,
    teller,
    new TellerETL(logger.child({ service: 'TellerETL' }), prisma, teller, cryptoService),
    cryptoService,
    '',
    env.NX_TELLER_ENV === 'sandbox'
)

// account-connection

const accountConnectionProviderFactory = new AccountConnectionProviderFactory({
    plaid: plaidService,
    finicity: finicityService,
    teller: tellerService,
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

export const accountConnectionService = new AccountConnectionService(
    logger.child({ service: 'AccountConnectionService' }),
    prisma,
    accountConnectionProviderFactory,
    balanceSyncStrategyFactory,
    securityPricingService,
    queueService.getQueue('sync-account-connection')
)

const transactionService = new TransactionService(
    logger.child({ service: 'TransactionService' }),
    prisma
)

export const accountConnectionProcessor: IAccountConnectionProcessor =
    new AccountConnectionProcessor(
        logger.child({ service: 'AccountConnectionProcessor' }),
        accountConnectionService,
        transactionService,
        accountConnectionProviderFactory
    )

// account

export const accountQueryService: IAccountQueryService = new AccountQueryService(
    logger.child({ service: 'AccountQueryService' }),
    pgService
)

export const accountService: IAccountService = new AccountService(
    logger.child({ service: 'AccountService' }),
    prisma,
    accountQueryService,
    queueService.getQueue('sync-account'),
    queueService.getQueue('sync-account-connection'),
    balanceSyncStrategyFactory
)

const accountProviderFactory = new AccountProviderFactory({
    // Since these are not in use yet, just commenting out for now
    // property: propertyService,
    // vehicle: vehicleService,
})

export const accountProcessor: IAccountProcessor = new AccountProcessor(
    logger.child({ service: 'AccountProcessor' }),
    accountService,
    accountProviderFactory
)

// user

export const userService: IUserService = new UserService(
    logger.child({ service: 'UserService' }),
    prisma,
    accountQueryService,
    balanceSyncStrategyFactory,
    queueService.getQueue('sync-user'),
    queueService.getQueue('purge-user'),
    stripe
)

export const userProcessor: IUserProcessor = new UserProcessor(
    logger.child({ service: 'UserProcessor' }),
    prisma,
    userService,
    accountService,
    accountConnectionService,
    accountConnectionProviderFactory
)

// security-pricing

export const securityPricingProcessor: ISecurityPricingProcessor = new SecurityPricingProcessor(
    logger.child({ service: 'SecurityPricingProcessor' }),
    securityPricingService
)

// institution

const institutionProviderFactory = new InstitutionProviderFactory({
    PLAID: plaidService,
    FINICITY: finicityService,
})

export const institutionService: IInstitutionService = new InstitutionService(
    logger.child({ service: 'InstitutionService' }),
    prisma,
    pgService,
    institutionProviderFactory
)

// worker services

export const workerErrorHandlerService = new WorkerErrorHandlerService(
    logger.child({ service: 'WorkerErrorHandlerService' })
)

// send-email

export const emailService: IEmailService = new EmailService(
    logger.child({ service: 'EmailService' }),
    postmark,
    {
        from: env.NX_POSTMARK_FROM_ADDRESS,
        replyTo: env.NX_POSTMARK_REPLY_TO_ADDRESS,
    }
)

export const emailProcessor: IEmailProcessor = new EmailProcessor(
    logger.child({ service: 'EmailProcessor' }),
    prisma,
    emailService
)
