import { PrismaClient, SecurityProvider } from '@prisma/client'
import winston from 'winston'
import Redis from 'ioredis'
import nock from 'nock'
import type { ISecurityPricingService } from '@maybe-finance/server/features'
import { SecurityPricingService } from '@maybe-finance/server/features'
import type { IMarketDataService } from '@maybe-finance/server/shared'
import {
    RedisCacheBackend,
    CacheService,
    ServerUtil,
    PolygonMarketDataService,
} from '@maybe-finance/server/shared'
import { PolygonTestData } from '../../../../../tools/test-data'

const prisma = new PrismaClient()

const redis = new Redis(process.env.NX_REDIS_URL as string, {
    retryStrategy: ServerUtil.redisRetryStrategy({ maxAttempts: 1 }),
})

beforeAll(() => {
    process.env.CI = 'true'
    nock.disableNetConnect()

    nock('https://api.polygon.io')
        .get((uri) => uri.includes('/v2/snapshot/locale/us/markets/stocks/tickers'))
        .reply(200, PolygonTestData.snapshotAllTickers)
        .persist()

    nock('https://api.polygon.io')
        .get((uri) => uri.includes('/v2/aggs/grouped/locale/us/market/stocks'))
        .reply(200, PolygonTestData.dailyPricing)
        .persist()

    nock('https://api.polygon.io')
        .get((uri) => uri.includes('/v3/reference/exchanges'))
        .reply(200, PolygonTestData.getExchanges)
        .persist()

    nock('https://api.polygon.io')
        .get(
            (uri) =>
                uri.includes('/v3/reference/tickers') &&
                uri.includes('market=stocks') &&
                uri.includes('exchange=XNAS')
        )
        .reply(200, PolygonTestData.getNASDAQTickers)
        .persist()

    nock('https://api.polygon.io')
        .get(
            (uri) =>
                uri.includes('/v3/reference/tickers') &&
                uri.includes('market=stocks') &&
                uri.includes('exchange=XNYS')
        )
        .reply(200, PolygonTestData.getNYSETickers)
        .persist()
})

afterAll(async () => {
    process.env.CI = ''
    await Promise.allSettled([prisma.$disconnect(), redis.disconnect()])
})

describe('security pricing sync for non basic tier', () => {
    let securityPricingService: ISecurityPricingService

    beforeEach(async () => {
        const logger = winston.createLogger({
            level: 'debug',
            transports: new winston.transports.Console({ format: winston.format.simple() }),
        })

        const cacheService = new CacheService(
            logger.child({ service: 'CacheService' }),
            new RedisCacheBackend(redis)
        )

        const marketDataService: IMarketDataService = new PolygonMarketDataService(
            logger.child({ service: 'PolygonMarketDataService' }),
            'TEST',
            cacheService
        )

        securityPricingService = new SecurityPricingService(
            logger.child({ service: 'SecurityPricingService' }),
            prisma,
            marketDataService
        )

        // reset db records
        await prisma.security.deleteMany({
            where: {
                providerName: SecurityProvider.other,
            },
        })
        await prisma.security.createMany({
            data: [{ symbol: 'AAPL' }, { symbol: 'VOO' }],
        })
    })

    it('syncs', async () => {
        // sync 2x to catch any possible caching I/O issues
        await securityPricingService.syncAll()
        await securityPricingService.syncAll()
    })
})

describe('security pricing sync for basic tier', () => {
    let securityPricingService: ISecurityPricingService

    beforeEach(async () => {
        const logger = winston.createLogger({
            level: 'debug',
            transports: new winston.transports.Console({ format: winston.format.simple() }),
        })

        const cacheService = new CacheService(
            logger.child({ service: 'CacheService' }),
            new RedisCacheBackend(redis)
        )

        const marketDataService: IMarketDataService = new PolygonMarketDataService(
            logger.child({ service: 'PolygonMarketDataService' }),
            'TEST',
            cacheService
        )

        securityPricingService = new SecurityPricingService(
            logger.child({ service: 'SecurityPricingService' }),
            prisma,
            marketDataService
        )

        // reset db records
        await prisma.security.deleteMany({
            where: {
                providerName: SecurityProvider.other,
            },
        })
        await prisma.security.createMany({
            data: [{ symbol: 'AAPL' }, { symbol: 'VOO' }],
        })
    })
    it('syncs', async () => {
        // sync 2x to catch any possible caching I/O issues
        await securityPricingService.syncAll()
        await securityPricingService.syncAll()
    })
})

describe('us stock ticker sync', () => {
    let securityPricingService: ISecurityPricingService

    beforeEach(async () => {
        const logger = winston.createLogger({
            level: 'debug',
            transports: new winston.transports.Console({ format: winston.format.simple() }),
        })

        const cacheService = new CacheService(
            logger.child({ service: 'CacheService' }),
            new RedisCacheBackend(redis)
        )

        const marketDataService: IMarketDataService = new PolygonMarketDataService(
            logger.child({ service: 'PolygonMarketDataService' }),
            'TEST',
            cacheService
        )

        securityPricingService = new SecurityPricingService(
            logger.child({ service: 'SecurityPricingService' }),
            prisma,
            marketDataService
        )

        // reset db records
        await prisma.security.deleteMany()
    })

    it('syncs', async () => {
        // sync 2x to catch any possible caching I/O issues
        await securityPricingService.syncUSStockTickers()
        await securityPricingService.syncUSStockTickers()
        expect(await prisma.security.count()).toEqual(20)
    })
})
