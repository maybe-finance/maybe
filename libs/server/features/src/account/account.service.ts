import type { Logger } from 'winston'
import type { SyncAccountQueue, SyncConnectionQueue } from '@maybe-finance/server/shared'
import type { IBalanceSyncStrategyFactory } from '../account-balance'
import type { IAccountQueryService } from './account-query.service'
import type {
    Account,
    AccountCategory,
    AccountClassification,
    User,
    PrismaClient,
    Prisma,
    InvestmentTransactionCategory,
} from '@prisma/client'
import _ from 'lodash'
import { DateTime } from 'luxon'
import { SharedType, AccountUtil, DateUtil } from '@maybe-finance/shared'
import { DbUtil } from '@maybe-finance/server/shared'

export interface IAccountService {
    get(id: Account['id']): Promise<Account>
    getAll(userId: User['id']): Promise<SharedType.AccountsResponse>
    getAccountRollup(
        userId: User['id'],
        start?: string,
        end?: string,
        interval?: SharedType.TimeSeriesInterval
    ): Promise<SharedType.AccountRollup>
    sync(id: Account['id']): Promise<Account>
    syncBalances(id: Account['id']): Promise<Account>
    create(
        data: Prisma.AccountUncheckedCreateInput,
        initialValuations?: Prisma.ValuationCreateNestedManyWithoutAccountInput
    ): Promise<Account>
    update(id: Account['id'], data: Prisma.AccountUncheckedUpdateInput): Promise<Account>
    delete(id: Account['id']): Promise<Account>
}

export class AccountService implements IAccountService {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly queryService: IAccountQueryService,
        private readonly syncAccountQueue: SyncAccountQueue,
        private readonly syncConnectionQueue: SyncConnectionQueue,
        private readonly balanceSyncStrategyFactory: IBalanceSyncStrategyFactory
    ) {}

    async get(id: Account['id']) {
        return this.prisma.account.findUniqueOrThrow({
            where: { id },
            include: { accountConnection: true },
        })
    }

    /**
     * A user can have account associated with an `AccountConnection` or directly tied to their profile
     *
     * To retrieve all accounts, check both `Account` and `AccountConnection` tables for a non-null `userId`
     */
    async getAll(userId: User['id']): Promise<SharedType.AccountsResponse> {
        const [accounts, connections] = await Promise.all([
            this.prisma.account.findMany({
                where: { userId },
                orderBy: { id: 'asc' },
            }),
            this.prisma.accountConnection.findMany({
                where: { userId },
                include: {
                    accounts: {
                        orderBy: { id: 'asc' },
                    },
                },
                orderBy: { id: 'asc' },
            }),
        ])

        const activeConnectionSyncJobs = await this.syncConnectionQueue.getActiveJobs()

        return {
            accounts,
            connections: connections.map((connection) => {
                const job = activeConnectionSyncJobs.find(
                    (job) => job.data.accountConnectionId === connection.id
                )

                const progress = job ? job.progress() : null

                return {
                    ...connection,
                    syncProgress:
                        progress != null &&
                        typeof progress === 'object' &&
                        typeof progress.description === 'string'
                            ? progress
                            : undefined,
                }
            }),
        }
    }

    async getAccountDetails(id: Account['id']) {
        return this.prisma.account.findUniqueOrThrow({
            where: { id },
            include: {
                accountConnection: true,
                transactions: {
                    take: SharedType.PageSize.Transaction,
                },
                investmentTransactions: {
                    take: SharedType.PageSize.InvestmentTransaction,
                },
                valuations: {
                    take: SharedType.PageSize.Valuation,
                },
                holdings: {
                    include: {
                        security: true,
                    },
                    take: SharedType.PageSize.Holding,
                },
            },
        })
    }

    async create(
        data: Omit<Prisma.AccountUncheckedCreateInput, 'category'>,
        initialValuations?: Prisma.ValuationCreateNestedManyWithoutAccountInput
    ) {
        return this.prisma.account.create({
            data: {
                ...data,
                valuations: initialValuations,
            },
        })
    }

    async update(id: Account['id'], data: Prisma.AccountUncheckedUpdateInput) {
        const account = await this.prisma.account.update({
            where: { id },
            data,
        })
        return account
    }

    async sync(id: Account['id']) {
        const account = await this.get(id)
        await this.syncAccountQueue.add('sync-account', { accountId: account.id })
        return account
    }

    async syncBalances(id: Account['id']) {
        const account = await this.get(id)
        const strategy = this.balanceSyncStrategyFactory.for(account)

        const profiler = this.logger.startTimer()
        await strategy.syncAccountBalances(account)
        profiler.done({ message: `synced account ${account.id} balances` })

        return account
    }

    async delete(id: Account['id']) {
        return this.prisma.account.delete({ where: { id } })
    }

    async getTransactions(accountId: Account['id'], page = 0, start?: DateTime, end?: DateTime) {
        const [transactions, totalTransactions] = await this.prisma.$transaction([
            this.prisma.$queryRaw<SharedType.TransactionEnriched[]>`
                SELECT 
                    *
                FROM transactions_enriched t
                WHERE 
                    t."accountId" = ${accountId}
                    AND (${start?.toISODate()}::date IS NULL OR t.date >= ${start?.toISODate()}::date)
                    AND (${end?.toISODate()}::date IS NULL OR t.date <= ${end?.toISODate()}::date)
                ORDER BY t.date desc
                LIMIT ${SharedType.PageSize.Transaction}
                OFFSET ${page * SharedType.PageSize.Transaction}
            `,
            this.prisma.transaction.count({
                where: {
                    accountId,
                    date: {
                        gte: start?.toJSDate(),
                        lte: end?.toJSDate(),
                    },
                },
            }),
        ])

        return {
            transactions,
            totalTransactions,
        }
    }

    async getHoldings(
        accountId: Account['id'],
        page = 0,
        pageSize = SharedType.PageSize.Holding
    ): Promise<SharedType.AccountHoldingResponse> {
        const [holdings, totalHoldings] = await Promise.all([
            this.queryService.getHoldingsEnriched(accountId, { page, pageSize }),
            this.prisma.holding.count({ where: { accountId } }),
        ])

        return {
            holdings: holdings.map((h) => {
                return {
                    id: h.id,
                    securityId: h.security_id,
                    name: h.name,
                    symbol: h.symbol,
                    quantity: h.quantity,
                    sharesPerContract: h.shares_per_contract,
                    costBasis: h.cost_basis_per_share,
                    costBasisUser: h.cost_basis_user,
                    costBasisProvider: h.cost_basis_provider,
                    price: h.price,
                    value: h.value,
                    trend: {
                        total: h.cost_basis ? DbUtil.calculateTrend(h.cost_basis, h.value) : null,
                        today: h.price_prev
                            ? DbUtil.calculateTrend(h.price_prev.times(h.quantity), h.value)
                            : null,
                    },
                    excluded: h.excluded,
                }
            }),
            totalHoldings,
        }
    }

    async getInvestmentTransactions(
        accountId: Account['id'],
        page = 0,
        start?: DateTime,
        end?: DateTime,
        category?: InvestmentTransactionCategory,
        pageSize = SharedType.PageSize.InvestmentTransaction
    ) {
        const where = {
            accountId,
            date: {
                gte: start?.toJSDate(),
                lte: end?.toJSDate(),
            },
            category,
        }

        const [investmentTransactions, totalInvestmentTransactions] =
            await this.prisma.$transaction([
                this.prisma.investmentTransaction.findMany({
                    where,
                    include: {
                        security: true,
                    },
                    orderBy: {
                        date: 'desc',
                    },
                    skip: page * pageSize,
                    take: pageSize,
                }),
                this.prisma.investmentTransaction.count({ where }),
            ])

        return {
            investmentTransactions,
            totalInvestmentTransactions,
        }
    }

    async getBalance(
        accountId: Account['id'],
        date: string = DateTime.utc().plus({ days: 1 }).toISODate() // default to one day here to ensure we're grabbing the most recent date's balance
    ): Promise<SharedType.AccountBalanceTimeSeriesData> {
        const [balance] = await this.queryService.getBalanceSeries(accountId, date, date, 'days')

        return {
            date: balance.date,
            balance: balance.balance,
        }
    }

    async getBalances(
        accountId: Account['id'],
        start = DateTime.utc().minus({ years: 2 }).toISODate(),
        end = DateTime.utc().toISODate(),
        interval?: SharedType.TimeSeriesInterval
    ): Promise<SharedType.AccountBalanceResponse> {
        interval = interval ?? DateUtil.calculateTimeSeriesInterval(start, end)

        const [balances, today, minDate] = await Promise.all([
            this.queryService.getBalanceSeries(accountId, start, end, interval),
            this.getBalance(accountId),
            this.getOldestBalanceDate(accountId),
        ])

        return {
            series: {
                interval,
                start,
                end,
                data: balances,
            },
            today,
            minDate,
            trend: DbUtil.calculateTrend(
                balances[0].balance,
                balances[balances.length - 1].balance
            ),
        }
    }

    async getReturns(
        accountId: Account['id'],
        start = DateTime.utc().minus({ years: 2 }).toISODate(),
        end = DateTime.utc().toISODate()
    ): Promise<SharedType.AccountReturnTimeSeriesData[]> {
        const returnSeries = await this.queryService.getReturnSeries(accountId, start, end)

        return returnSeries.map(
            ({
                date,
                rate_of_return: rateOfReturn,
                contributions,
                contributions_period: contributionsPeriod,
            }) => ({
                date,
                account: {
                    contributions,
                    contributionsPeriod,
                    rateOfReturn,
                },
            })
        )
    }

    async getAccountRollup(
        userId: User['id'],
        start = DateTime.utc().minus({ years: 2 }).toISODate(),
        end = DateTime.utc().toISODate(),
        interval?: SharedType.TimeSeriesInterval
    ): Promise<SharedType.AccountRollup> {
        interval = interval ?? DateUtil.calculateTimeSeriesInterval(start, end)

        const rollup = await this.queryService.getRollup({ userId }, start, end, interval)

        const toTimeSeries = (rows: typeof rollup): SharedType.AccountRollupTimeSeries => {
            return {
                interval: interval!,
                start,
                end,
                data: rows.map(({ date, balance, rollup_pct, total_pct }) => ({
                    date,
                    balance,
                    rollupPct: rollup_pct,
                    totalPct: total_pct,
                })),
            }
        }

        // Arranges the flattened SQL query into a hierarchical tree for the UI
        return _(rollup)
            .groupBy((r) => r.classification)
            .omit('null')
            .mapValues((classificationRows, classification) => {
                return {
                    key: classification as AccountClassification,
                    title: classification === 'asset' ? 'Assets' : 'Debts',
                    balances: toTimeSeries(
                        classificationRows.filter((r) => r.grouping === 'classification')
                    ),
                    items: _(classificationRows)
                        .groupBy((r) => r.category)
                        .omit('null')
                        .mapValues((categoryRows, category) => {
                            return {
                                key: category as AccountCategory,
                                title: AccountUtil.CATEGORIES[category as AccountCategory].plural,
                                balances: toTimeSeries(
                                    categoryRows.filter((r) => r.grouping === 'category')
                                ),
                                items: _(categoryRows)
                                    .groupBy((r) => r.id)
                                    .omit('null')
                                    .mapValues((accountRows) => {
                                        const [{ account }] = accountRows

                                        if (!account) {
                                            this.logger.warn('accountRow', accountRows[0])
                                            throw new Error(
                                                `accountRow is missing account data (rows: ${accountRows.length})`
                                            )
                                        }

                                        return {
                                            ...account,
                                            syncing:
                                                account.syncStatus !== 'IDLE' ||
                                                (!!account.connection &&
                                                    account.connection.syncStatus !== 'IDLE'),
                                            balances: toTimeSeries(
                                                accountRows.filter((r) => r.grouping === 'account')
                                            ),
                                        }
                                    })
                                    .values()
                                    .value(),
                            }
                        })
                        .values()
                        .value(),
                }
            })
            .values()
            .value()
    }

    /**
     * If the user has defined a `start_date`, use that. Otherwise, find the oldest balance record.
     */
    private async getOldestBalanceDate(accountId: Account['id']): Promise<string> {
        const account = await this.prisma.account.findUnique({
            where: { id: accountId },
            select: { startDate: true },
        })

        if (account?.startDate) {
            return DateTime.fromJSDate(account.startDate, { zone: 'utc' }).toISODate()
        }

        const {
            _min: { date: minDate },
        } = await this.prisma.accountBalance.aggregate({
            where: { accountId },
            _min: { date: true },
        })

        return minDate
            ? DateTime.fromJSDate(minDate, { zone: 'utc' }).toISODate()
            : DateTime.utc().minus({ years: 2 }).toISODate()
    }
}
