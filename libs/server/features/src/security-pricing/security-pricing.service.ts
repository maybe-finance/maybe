import type { PrismaClient, Security } from '@prisma/client'
import { SecurityProvider, AssetClass } from '@prisma/client'
import type {
    IMarketDataService,
    LivePricing,
    EndOfDayPricing,
    TSecurity,
} from '@maybe-finance/server/shared'
import type { Logger } from 'winston'
import { Prisma } from '@prisma/client'
import { DateTime } from 'luxon'
import { SharedUtil } from '@maybe-finance/shared'
import _ from 'lodash'

export interface ISecurityPricingService {
    sync(
        security: Pick<Security, 'assetClass' | 'currencyCode' | 'id' | 'symbol'>,
        syncStart?: string
    ): Promise<void>
    syncAll(): Promise<void>
    syncUSStockTickers(): Promise<void>
}

export class SecurityPricingService implements ISecurityPricingService {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly marketDataService: IMarketDataService
    ) {}

    async sync(
        security: Pick<Security, 'assetClass' | 'currencyCode' | 'id' | 'symbol'>,
        syncStart?: string
    ) {
        const dailyPricing = await this.marketDataService.getDailyPricing(
            security,
            syncStart
                ? DateTime.fromISO(syncStart, { zone: 'utc' })
                : DateTime.utc().minus({ years: 2 }),
            DateTime.now()
        )

        if (!dailyPricing.length) return

        this.logger.debug(
            `fetched ${dailyPricing.length} daily prices for Security{id=${security.id} symbol=${security.symbol})`
        )

        await this.prisma.$transaction([
            this.prisma.$executeRaw`
              INSERT INTO security_pricing (security_id, date, price_close, price_as_of, source)
              VALUES
                ${Prisma.join(
                    dailyPricing.map(
                        ({ date, priceClose }) =>
                            Prisma.sql`(
                              ${security.id},
                              ${date.toISODate()}::date,
                              ${priceClose},
                              NOW(),
                              ${this.marketDataService.source}
                            )`
                    )
                )}
              ON CONFLICT (security_id, date) DO UPDATE
              SET
                price_close = EXCLUDED.price_close,
                price_as_of = EXCLUDED.price_as_of,
                source = EXCLUDED.source;
            `,
            this.prisma.security.update({
                where: { id: security.id },
                data: {
                    pricingLastSyncedAt: new Date(),
                },
            }),
        ])
    }

    async syncAll() {
        if (!process.env.NX_POLYGON_API_KEY) {
            this.logger.warn('No polygon API key found, skipping sync')
            return
        }

        const profiler = this.logger.startTimer()

        for await (const securities of SharedUtil.paginateIt({
            pageSize: 1000,
            fetchData: (offset, count) =>
                this.prisma.security.findMany({
                    select: {
                        assetClass: true,
                        currencyCode: true,
                        id: true,
                        symbol: true,
                    },
                    skip: offset,
                    take: count,
                }),
        })) {
            let pricingData: LivePricing<TSecurity>[] | EndOfDayPricing<TSecurity>[]
            if (!process.env.NX_POLYGON_TIER || process.env.NX_POLYGON_TIER === 'basic') {
                try {
                    const allPrices = await this.marketDataService.getAllDailyPricing()
                    pricingData = await this.marketDataService.getEndOfDayPricing(
                        securities,
                        allPrices
                    )
                } catch (err) {
                    this.logger.warn('Polygon fetch for EOD pricing failed', err)
                    pricingData = []
                }
            } else {
                try {
                    pricingData = await this.marketDataService.getLivePricing(securities)
                } catch (err) {
                    this.logger.warn('Polygon fetch for live pricing failed', err)
                    pricingData = []
                }
            }

            const prices = pricingData.filter((p) => !!p.pricing)

            this.logger.debug(
                `Fetched live pricing for ${prices.length} / ${securities.length} securities`
            )

            if (prices.length === 0) break

            await this.prisma.$transaction([
                this.prisma.$executeRaw`
                  INSERT INTO security_pricing (security_id, date, price_close, price_as_of, source)
                  VALUES
                    ${Prisma.join(
                        prices.map(
                            ({ security, pricing }) =>
                                Prisma.sql`(
                                  ${security.id},
                                  ${pricing!.updatedAt.toISODate()}::date,
                                  ${pricing!.price},
                                  ${pricing!.updatedAt.toJSDate()},
                                  ${this.marketDataService.source}
                                )`
                        )
                    )}
                  ON CONFLICT (security_id, date) DO UPDATE
                  SET
                    price_close = EXCLUDED.price_close,
                    price_as_of = EXCLUDED.price_as_of,
                    source = EXCLUDED.source;
                `,
                // Update today's balance record for any accounts with holdings containing synced securities
                this.prisma.$executeRaw`
                  INSERT INTO account_balance (account_id, date, balance)
                  SELECT
                    h.account_id,
                    NOW() AS date,
                    SUM(COALESCE(h.quantity * sp.price_close * COALESCE(s.shares_per_contract, 1), h.value)) AS balance
                  FROM
                    holding h
                    INNER JOIN security s ON s.id = h.security_id
                    LEFT JOIN (
                      SELECT DISTINCT ON (security_id)
                        *
                      FROM
                        security_pricing
                      ORDER BY
                        security_id, date DESC
                    ) sp ON sp.security_id = s.id
                  WHERE
                    h.account_id IN (
                      SELECT
                        a.id
                      FROM
                        account a
                        INNER JOIN holding h ON h.account_id = a.id
                      WHERE
                        h.security_id IN (${Prisma.join(prices.map((p) => p.security.id))})
                    )
                  GROUP BY
                    h.account_id
                  ON CONFLICT (account_id, date) DO UPDATE
                  SET
                    balance = EXCLUDED.balance;
                `,
            ])
        }

        profiler.done({ message: 'Synced all securities' })
    }

    async syncUSStockTickers() {
        if (!process.env.NX_POLYGON_API_KEY) {
            this.logger.warn('No polygon API key found, skipping sync')
            return
        }

        const profiler = this.logger.startTimer()

        const usStockTickers = await this.marketDataService.getUSStockTickers()

        if (!usStockTickers.length) return

        this.logger.debug(`fetched ${usStockTickers.length} stock tickers`)

        _.chunk(usStockTickers, 1_000).map((chunk) => {
            return this.prisma.$transaction([
                this.prisma.$executeRaw`
                    INSERT INTO security (name, symbol, currency_code, exchange_acronym, exchange_mic, exchange_name, provider_name, asset_class)
                    VALUES
                      ${Prisma.join(
                          chunk.map(
                              ({
                                  name,
                                  ticker,
                                  currency_name,
                                  exchangeAcronym,
                                  exchangeMic,
                                  exchangeName,
                              }) =>
                                  Prisma.sql`(
                                    ${name},
                                    ${ticker},
                                    ${currency_name?.toUpperCase()},
                                    ${exchangeAcronym},
                                    ${exchangeMic},
                                    ${exchangeName},
                                    ${SecurityProvider.polygon}::"SecurityProvider",
                                    ${AssetClass.stocks}::"AssetClass"
                                  )`
                          )
                      )}
                    ON CONFLICT (symbol, exchange_mic) DO UPDATE
                    SET
                      name = EXCLUDED.name,
                      currency_code = EXCLUDED.currency_code;
                  `,
            ])
        })

        profiler.done({ message: 'Synced US stock tickers' })
    }
}
