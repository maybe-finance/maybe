import { AssetClass, Prisma } from '@prisma/client'
import type { Security } from '@prisma/client'
import _ from 'lodash'
import { DateTime, Duration } from 'luxon'
import type { Logger } from 'winston'
import type { IRestClient } from '@polygon.io/client-js'
import { restClient } from '@polygon.io/client-js'
import type { SharedType } from '@maybe-finance/shared'
import { MarketUtil, SharedUtil } from '@maybe-finance/shared'
import type { CacheService } from '.'
import { toDecimal } from '../utils/db-utils'
import type { ITickersResults } from '@polygon.io/client-js/lib/rest/reference/tickers'
import type { IAggs } from '@polygon.io/client-js/lib/rest/stocks/aggregates'

type DailyPricing = {
    date: DateTime
    priceClose: Prisma.Decimal
}

type LivePricing<TSecurity> = {
    security: TSecurity
    pricing: {
        ticker: string
        price: Prisma.Decimal
        change: Prisma.Decimal
        changePct: Prisma.Decimal
        updatedAt: DateTime
    } | null
}

type EndOfDayPricing<TSecurity> = {
    security: TSecurity
    pricing: {
        ticker: string
        price: Prisma.Decimal
        change: Prisma.Decimal
        changePct: Prisma.Decimal
        updatedAt: DateTime
    }
}

type OptionDetails = {
    sharesPerContract: number | undefined
}

export interface IMarketDataService {
    /**
     * internal identifier for this market data source
     */
    get source(): string

    /**
     * fetches pricing info for inclusive date range
     */
    getDailyPricing<TSecurity extends Pick<Security, 'assetClass' | 'currencyCode' | 'symbol'>>(
        security: TSecurity,
        start: DateTime,
        end: DateTime
    ): Promise<DailyPricing[]>

    /**
     * fetches end of day pricing info for a batch of securities
     */
    getEndOfDayPricing<
        TSecurity extends Pick<Security, 'assetClass' | 'currencyCode' | 'id' | 'symbol'>
    >(
        securities: TSecurity[],
        allPricing: IAggs
    ): Promise<EndOfDayPricing<TSecurity>[]>

    /**
     * fetches all end of day pricing
     */

    getAllDailyPricing(): Promise<IAggs>

    /**
     * fetches up-to-date pricing info for a batch of securities
     */
    getLivePricing<
        TSecurity extends Pick<Security, 'assetClass' | 'currencyCode' | 'id' | 'symbol'>
    >(
        securities: TSecurity[]
    ): Promise<LivePricing<TSecurity>[]>

    /**
     * fetches options contract details
     */
    getOptionDetails(symbol: Security['symbol']): Promise<OptionDetails>

    getSecurityDetails(
        security: Pick<Security, 'assetClass' | 'currencyCode' | 'symbol'>
    ): Promise<SharedType.SecurityDetails>

    /**
     * fetches all US stock tickers
     */
    getUSStockTickers(): Promise<
        (ITickersResults & {
            exchangeAcronym: string
            exchangeMic: string
            exchangeName: string
        })[]
    >
}

export class PolygonMarketDataService implements IMarketDataService {
    private readonly api: IRestClient
    private shouldRateLimit = process.env.NX_POLYGON_TIER === 'basic' && !process.env.CI

    readonly source = 'polygon'

    constructor(
        private readonly logger: Logger,
        apiKey: string,
        private readonly cache: CacheService
    ) {
        this.api = restClient(apiKey)
    }

    async getDailyPricing<
        TSecurity extends Pick<Security, 'assetClass' | 'currencyCode' | 'symbol'>
    >(security: TSecurity, start: DateTime, end: DateTime): Promise<DailyPricing[]> {
        const ticker = getPolygonTicker(security)
        if (!ticker) return []

        /**
         * https://polygon.io/docs/stocks/get_v2_aggs_ticker__stocksticker__range__multiplier___timespan___from___to
         */
        const res = await this.api.stocks.aggregates(
            ticker.ticker,
            1,
            'day',
            start.toISODate(),
            end.toISODate()
        )

        return (
            res.results
                ?.filter(({ t, c }) => t != null && c != null)
                .map(({ t, c }) => ({
                    date: DateTime.fromMillis(t!, { zone: 'America/New_York' }),
                    priceClose: new Prisma.Decimal(c!),
                })) ?? []
        )
    }

    async getEndOfDayPricing<
        TSecurity extends Pick<Security, 'id' | 'symbol' | 'assetClass' | 'currencyCode'>
    >(securities: TSecurity[], allPricing: IAggs): Promise<EndOfDayPricing<TSecurity>[]> {
        const securitiesWithTicker = securities.map((security) => ({
            security,
            ticker: getPolygonTicker(security),
        }))
        const tickers = _(securitiesWithTicker)
            .map((s) => s.ticker)
            .filter(SharedUtil.nonNull)
            .uniqBy((t) => t.ticker)
            .sortBy((t) => [t.market, t.ticker])
            .value()

        const stockTickers = tickers.filter((t) => t.market === 'stocks').map((s) => s.ticker)

        if (stockTickers.length > 0) {
            return allPricing
                .results!.filter(({ t, c }) => t != null && c != null)
                .map((pricing) => {
                    const foundSecurity = securitiesWithTicker.find(
                        ({ ticker }) => ticker?.ticker === pricing.T
                    )
                    if (!foundSecurity) return null
                    return {
                        security: foundSecurity.security,
                        pricing: {
                            ticker: pricing.T!,
                            price: new Prisma.Decimal(pricing.c!),
                            change: new Prisma.Decimal(pricing.c! - pricing.o!),
                            changePct: new Prisma.Decimal(
                                ((pricing.c! - pricing.o!) / pricing.o!) * 100
                            ),
                            updatedAt: DateTime.fromMillis(pricing.t!, {
                                zone: 'America/New_York',
                            }),
                        },
                    }
                })
                .filter(SharedUtil.nonNull)
        } else {
            return []
        }
    }

    async getAllDailyPricing(): Promise<IAggs> {
        return await this.api.stocks.aggregatesGroupedDaily(
            DateTime.now().minus({ days: 1 }).toISODate(),
            {
                adjusted: 'true',
            }
        )
    }

    async getLivePricing<
        TSecurity extends Pick<Security, 'assetClass' | 'currencyCode' | 'id' | 'symbol'>
    >(securities: TSecurity[]): Promise<LivePricing<TSecurity>[]> {
        const securitiesWithTicker = securities.map((security) => ({
            security,
            ticker: getPolygonTicker(security),
        }))

        const tickers = _(securitiesWithTicker)
            .map((s) => s.ticker)
            .filter(SharedUtil.nonNull)
            .uniqBy((t) => t.ticker)
            .sortBy((t) => [t.market, t.ticker])
            .value()

        const stockTickers = tickers.filter((t) => t.market === 'stocks').map((s) => s.ticker)
        const optionTickers = tickers.filter((t) => t.market === 'options').map((o) => o.ticker)
        const cryptoTickers = tickers.filter((t) => t.market === 'crypto').map((c) => c.ticker)

        const [stocksSnapshot, optionsSnapshot, cryptoSnapshot] = await Promise.all([
            stockTickers.length > 0
                ? this.cache.getOrAdd(
                      `live-pricing[${stockTickers.join(',')}]`,
                      () => this._snapshotStocks(stockTickers),
                      Duration.fromObject({ minutes: 2 })
                  )
                : null,
            optionTickers.length > 0
                ? Promise.allSettled(
                      optionTickers.map((optionTicker) =>
                          this.cache
                              .getOrAdd(
                                  `live-pricing[${optionTicker}]`,
                                  () => this._snapshotOption(optionTicker),
                                  Duration.fromObject({ minutes: 2 })
                              )
                              .catch((err) => {
                                  this.logger.warn(
                                      `failed to get option snapshot for ${optionTicker}: ${err}`
                                  )
                                  return null
                              })
                      )
                  ).then((results) =>
                      results
                          .filter(SharedUtil.isFullfilled)
                          .map((r) => r.value)
                          .filter(SharedUtil.nonNull)
                  )
                : null,
            cryptoTickers.length > 0
                ? this.cache.getOrAdd(
                      `live-pricing[${cryptoTickers.join(',')}]`,
                      () => this._snapshotCrypto(cryptoTickers),
                      Duration.fromObject({ minutes: 2 })
                  )
                : null,
        ])

        return securitiesWithTicker.map(({ security, ticker }) => {
            if (!ticker) {
                return { security, pricing: null }
            }

            const snapshot =
                ticker.market === 'stocks'
                    ? stocksSnapshot?.find((s) => s.ticker === ticker.ticker)
                    : ticker.market === 'options'
                    ? optionsSnapshot?.find((o) => o.ticker === ticker.ticker)
                    : ticker.market === 'crypto'
                    ? cryptoSnapshot?.find((c) => c.ticker === ticker.ticker)
                    : null

            return { security, pricing: snapshot?.pricing ?? null }
        })
    }

    async getOptionDetails(symbol: Security['symbol']): Promise<OptionDetails> {
        const ticker = getPolygonTicker({
            assetClass: AssetClass.options,
            currencyCode: 'USD',
            symbol,
        })

        if (!ticker) {
            return { sharesPerContract: 100 }
        }

        const contractResponse = await this.api.reference.optionsContract(ticker.ticker)

        return {
            // https://github.com/polygon-io/client-js/issues/95
            sharesPerContract: (contractResponse.results as any)?.shares_per_contract,
        }
    }

    async getSecurityDetails(security: Pick<Security, 'assetClass' | 'currencyCode' | 'symbol'>) {
        const ticker = getPolygonTicker(security)
        if (!ticker || ticker.market === 'options') {
            return {}
        }

        const now = DateTime.now()
        const oneYearAgo = DateTime.now().minus({ weeks: 52 })

        try {
            const [snapshot, yearAggregate, details, financials, dividends] = await Promise.all([
                this.cache.getOrAdd(
                    `ticker-snapshot[${ticker}]`,
                    () => this.api.stocks.snapshotTicker(ticker.ticker),
                    Duration.fromObject({ minutes: 2 })
                ),

                this.cache.getOrAdd(
                    `ticker-year-aggregate[${ticker}]`,
                    () =>
                        this.api.stocks.aggregates(
                            ticker.ticker,
                            1,
                            'year',
                            oneYearAgo.toFormat('yyyy-MM-dd'),
                            now.toFormat('yyyy-MM-dd')
                        ),
                    Duration.fromObject({ minutes: 2 })
                ),

                this.cache.getOrAdd(
                    `ticker-details[${ticker}]`,
                    () => this.api.reference.tickerDetails(ticker.ticker),
                    Duration.fromObject({ hours: 12 })
                ),

                this.cache.getOrAdd(
                    `ticker-financials[${ticker}]`,
                    () => this.api.reference.stockFinancials({ ticker: ticker.ticker }),
                    Duration.fromObject({ minutes: 1 })
                ),

                this.cache.getOrAdd(
                    `ticker-dividends[${ticker}]`,
                    () =>
                        this.api.reference.dividends({
                            ticker: ticker.ticker,
                            'pay_date.gt': oneYearAgo.toFormat('yyyy-MM-dd'),
                            'pay_date.lte': now.toFormat('yyyy-MM-dd'),
                        }),
                    Duration.fromObject({ minutes: 1 })
                ),
            ])

            return {
                day: {
                    open: toDecimal(snapshot.ticker?.day?.o) ?? undefined,
                    prevClose: toDecimal(snapshot.ticker?.prevDay?.c) ?? undefined,
                    high: toDecimal(snapshot.ticker?.day?.h) ?? undefined,
                    low: toDecimal(snapshot.ticker?.day?.l) ?? undefined,
                },
                year: {
                    high: toDecimal(yearAggregate.results?.[0].h) ?? undefined,
                    low: toDecimal(yearAggregate.results?.[0].l) ?? undefined,
                    volume: toDecimal(yearAggregate.results?.[0].v) ?? undefined,
                    dividends:
                        toDecimal(
                            dividends.results?.reduce((sum, d) => sum + (d.cash_amount ?? 0), 0)
                        ) ?? undefined,
                },
                marketCap: toDecimal(details.results?.market_cap) ?? undefined,
                eps:
                    toDecimal(
                        financials.results?.[0]?.financials?.income_statement
                            ?.basic_earnings_per_share.value
                    ) ?? undefined,
            }
        } catch (e) {
            this.logger.warn(`Failed to get security details for ${ticker}: ${e}`)
        }

        return {}
    }

    async getUSStockTickers(): Promise<
        (ITickersResults & {
            exchangeAcronym: string
            exchangeMic: string
            exchangeName: string
        })[]
    > {
        const exchanges = await this.api.reference.exchanges({
            locale: 'us',
            asset_class: 'stocks',
        })

        const tickers: (ITickersResults & {
            exchangeAcronym: string
            exchangeMic: string
            exchangeName: string
        })[] = []
        for (const exchange of exchanges.results) {
            const exchangeTickers: (ITickersResults & {
                exchangeAcronym: string
                exchangeMic: string
                exchangeName: string
            })[] = await SharedUtil.paginateWithNextUrl({
                pageSize: 1000,
                delay: this.shouldRateLimit
                    ? {
                          onDelay: (message: string) => this.logger.debug(message),
                          milliseconds: 15_000, // Basic accounts rate limited at 5 calls / minute
                      }
                    : undefined,
                fetchData: async (limit, nextCursor) => {
                    try {
                        const { results, next_url } = await SharedUtil.withRetry(
                            () =>
                                this.api.reference.tickers({
                                    market: 'stocks',
                                    exchange: exchange.mic,
                                    cursor: nextCursor,
                                    limit: limit,
                                }),
                            { maxRetries: 1, delay: this.shouldRateLimit ? 15_000 : 0 }
                        )
                        const tickersWithExchange = results.map((ticker) => {
                            return {
                                ...ticker,
                                exchangeAcronym: exchange.acronymstring ?? '',
                                exchangeMic: exchange.mic ?? '',
                                exchangeName: exchange.name,
                            }
                        })
                        return { data: tickersWithExchange, nextUrl: next_url }
                    } catch (err) {
                        this.logger.error('Error while fetching tickers', err)
                        return { data: [], nextUrl: undefined }
                    }
                },
            })
            tickers.push(...exchangeTickers)
        }
        return tickers
    }

    private async _snapshotStocks(tickers: string[]) {
        /**
         * https://polygon.io/docs/stocks/get_v2_snapshot_locale_us_markets_stocks_tickers
         */
        const res = await this.api.stocks.snapshotAllTickers({
            tickers: tickers.join(','),
        })

        const snapshots = res.tickers ?? []

        // ENG-601: alert us if polygon returns any prices as 0
        const emptySnapshots =
            snapshots.filter((t) => !t.updated && !t.lastTrade?.t && !t.lastQuote?.t) ?? []

        if (emptySnapshots.length > 0) {
            this.logger.error(
                `polygon snapshot empty tickers: ${emptySnapshots.map((t) => t.ticker).join(',')}`
            )
        }

        return snapshots.map((snapshot) => {
            // extract the (p)rice + (t)ime to use for the live price
            // if the (t)ime is 0, we're dealing with an empty/zero snapshot from Polygon
            //
            // the order of priority for pricing that we use is:
            //
            // 1. The `day` snapshot object from Polygon (OHLCV)
            // 2. The `lastTrade`
            // 3. The `lastQuote` - we calculate the midpoint
            const [p, t] =
                // it's possible for a snapshot to have a valid `updated` time but
                // a zeroed out `snapshot.day` object which is why we check for both here
                snapshot.updated && snapshot.day && Object.values(snapshot.day).some((v) => v > 0)
                    ? [snapshot.day.c, snapshot.updated]
                    : snapshot.lastTrade && snapshot.lastTrade.t
                    ? [snapshot.lastTrade.p, snapshot.lastTrade.t]
                    : snapshot.lastQuote && snapshot.lastQuote.t
                    ? [_.mean([snapshot.lastQuote.P, snapshot.lastQuote.p]), snapshot.lastQuote.t]
                    : [null, null]

            return {
                ticker: snapshot.ticker,
                pricing:
                    t &&
                    snapshot.ticker &&
                    snapshot.todaysChange != null &&
                    snapshot.todaysChangePerc != null
                        ? {
                              ticker: snapshot.ticker,
                              price: new Prisma.Decimal(p!),
                              change: new Prisma.Decimal(snapshot.todaysChange),
                              changePct: new Prisma.Decimal(snapshot.todaysChangePerc),
                              updatedAt: DateTime.fromMillis(t / 1e6, {
                                  zone: 'America/New_York',
                              }),
                          }
                        : null,
            }
        })
    }

    private async _snapshotOption(ticker: string) {
        // https://polygon.io/docs/options/get_v3_reference_options_contracts__options_ticker
        const underlyingTicker =
            MarketUtil.getUnderlyingTicker(ticker) ??
            (await this.api.reference
                .optionsContract(ticker)
                .then(({ results: oc }) => oc?.underlying_ticker)
                .catch(() => null))

        if (!underlyingTicker) return null

        const { results: snapshot } = await this.api.options.snapshotOptionContract(
            underlyingTicker,
            ticker
        )

        return {
            ticker,
            pricing:
                snapshot?.day?.close != null &&
                snapshot.day.change != null &&
                snapshot.day.change_percent != null &&
                snapshot.day.last_updated != null
                    ? {
                          ticker: ticker,
                          price: new Prisma.Decimal(snapshot.day.close),
                          change: new Prisma.Decimal(snapshot.day.change),
                          changePct: new Prisma.Decimal(snapshot.day.change_percent),
                          updatedAt: DateTime.fromMillis(snapshot.day.last_updated / 1e6, {
                              zone: 'America/New_York',
                          }),
                      }
                    : null,
        }
    }

    private async _snapshotCrypto(tickers: string[]) {
        /**
         * https://polygon.io/docs/crypto/get_v2_snapshot_locale_global_markets_crypto_tickers
         */
        const res = await this.api.crypto.snapshotAllTickers({
            tickers: tickers.join(','),
        })

        const snapshots = res.tickers ?? []

        // ENG-601: alert us if polygon returns any prices as 0
        const emptySnapshots = snapshots.filter((t) => !t.updated && !t.lastTrade?.t)

        if (emptySnapshots.length > 0) {
            this.logger.error(
                `polygon snapshot empty tickers: ${emptySnapshots.map((t) => t.ticker).join(',')}`
            )
        }

        return snapshots.map((snapshot) => {
            // extract the (p)rice + (t)ime to use for the live price
            // if the (t)ime is 0, we're dealing with an empty/zero snapshot from Polygon
            //
            // the order of priority for pricing that we use is:
            //
            // 1. The `day` snapshot object from Polygon (OHLCV)
            // 2. The `lastTrade`
            // 3. The `lastQuote` - we calculate the midpoint
            const [p, t] =
                // it's possible for a snapshot to have a valid `updated` time but
                // a zeroed out `snapshot.day` object which is why we check for both here
                snapshot.updated && snapshot.day && Object.values(snapshot.day).some((v) => v > 0)
                    ? [snapshot.day.c, snapshot.updated]
                    : snapshot.lastTrade && snapshot.lastTrade.t
                    ? [snapshot.lastTrade.p, snapshot.lastTrade.t]
                    : [null, null]

            return {
                ticker: snapshot.ticker,
                pricing:
                    t &&
                    snapshot.ticker &&
                    snapshot.todaysChange != null &&
                    snapshot.todaysChangePerc != null
                        ? {
                              ticker: snapshot.ticker,
                              price: new Prisma.Decimal(p!),
                              change: new Prisma.Decimal(snapshot.todaysChange),
                              changePct: new Prisma.Decimal(snapshot.todaysChangePerc),
                              updatedAt: DateTime.fromMillis(t / 1e6, {
                                  zone: 'America/New_York',
                              }),
                          }
                        : null,
            }
        })
    }
}

class PolygonTicker {
    constructor(readonly market: 'stocks' | 'options' | 'fx' | 'crypto', readonly ticker: string) {}

    get key() {
        return `${this.market}|${this.ticker}`
    }

    /** override so this object can be used directly in string interpolation for cache keys */
    toString() {
        return this.key
    }
}

export function getPolygonTicker({
    assetClass,
    currencyCode,
    symbol,
}: Pick<Security, 'assetClass' | 'currencyCode' | 'symbol'>): PolygonTicker | null {
    if (!symbol) return null

    switch (assetClass) {
        case AssetClass.options: {
            return new PolygonTicker('options', `O:${symbol}`)
        }
        case AssetClass.crypto: {
            return new PolygonTicker('crypto', `X:${symbol}${currencyCode}`)
        }
        case AssetClass.cash: {
            return symbol === currencyCode
                ? null // if the symbol matches the currencyCode then we're just dealing with a basic cash holding
                : new PolygonTicker('fx', `C:${symbol}${currencyCode}`)
        }
    }

    if (MarketUtil.isOptionTicker(symbol)) {
        return new PolygonTicker('options', `O:${symbol}`)
    }

    return new PolygonTicker('stocks', symbol)
}
