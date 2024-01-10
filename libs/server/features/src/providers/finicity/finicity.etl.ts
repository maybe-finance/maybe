import type { AccountConnection, PrismaClient } from '@prisma/client'
import type { Logger } from 'winston'
import { SharedUtil, AccountUtil, type SharedType } from '@maybe-finance/shared'
import type { FinicityApi, FinicityTypes } from '@maybe-finance/finicity-api'
import { DbUtil, FinicityUtil, type IETL } from '@maybe-finance/server/shared'
import { Prisma } from '@prisma/client'
import _ from 'lodash'
import { DateTime } from 'luxon'

type FinicitySecurity = {
    securityName: string | undefined
    symbol: string | undefined
    currentPrice: number | undefined
    currentPriceDate: number | undefined
    securityId: string
    securityIdType: string
    type: string | undefined
    assetClass: string | undefined
    fiAssetClass: string | undefined
}

export type FinicityRawData = {
    accounts: FinicityTypes.CustomerAccount[]
    transactions: FinicityTypes.Transaction[]
    transactionsDateRange: SharedType.DateRange<DateTime>
}

export type FinicityData = {
    accounts: FinicityTypes.CustomerAccount[]
    positions: (FinicityTypes.CustomerAccountPosition & {
        accountId: FinicityTypes.CustomerAccount['id']
        security: FinicitySecurity
    })[]
    transactions: FinicityTypes.Transaction[]
    transactionsDateRange: SharedType.DateRange<DateTime>
    investmentTransactions: (FinicityTypes.Transaction & {
        security: Pick<FinicitySecurity, 'securityId' | 'securityIdType' | 'symbol'> | null
    })[]
    investmentTransactionsDateRange: SharedType.DateRange<DateTime>
}

type Connection = Pick<
    AccountConnection,
    'id' | 'userId' | 'finicityInstitutionId' | 'finicityInstitutionLoginId'
>

/**
 * Determines if a Finicity Transaction should be treated as an investment_transaction
 */
function isInvestmentTransaction(
    t: Pick<
        FinicityTypes.Transaction,
        'securityId' | 'symbol' | 'ticker' | 'investmentTransactionType'
    >
) {
    return (
        t.securityId != null ||
        t.symbol != null ||
        t.ticker != null ||
        t.investmentTransactionType != null
    )
}

/**
 * Normalizes Finicity identifiers to handle cases where transactions/positions don't contain a valid
 * securityId/securityIdType pair
 */
function getSecurityIdAndType(
    txnOrPos: Pick<
        FinicityTypes.Transaction | FinicityTypes.CustomerAccountPosition,
        'securityId' | 'securityIdType' | 'symbol' | 'ticker'
    >
): { securityId: string; securityIdType: string } | null {
    const securityId: string | null | undefined =
        txnOrPos.securityId || txnOrPos.symbol || txnOrPos.ticker

    if (!securityId) return null

    const securityIdType =
        txnOrPos.securityIdType ||
        (txnOrPos.securityId ? '__SECURITY_ID__' : txnOrPos.symbol ? '__SYMBOL__' : '__TICKER__')

    return {
        securityId,
        securityIdType,
    }
}

/** returns unique identifier for a given security (used for de-duping) */
function getSecurityId(s: Pick<FinicitySecurity, 'securityId' | 'securityIdType'>): string {
    return `${s.securityIdType}|${s.securityId}`
}

export class FinicityETL implements IETL<Connection, FinicityRawData, FinicityData> {
    public constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly finicity: Pick<
            FinicityApi,
            'getCustomerAccounts' | 'getAccountTransactions'
        >
    ) {}

    async extract(connection: Connection): Promise<FinicityRawData> {
        if (!connection.finicityInstitutionId || !connection.finicityInstitutionLoginId) {
            throw new Error(
                `connection ${connection.id} is missing finicityInstitutionId or finicityInstitutionLoginId`
            )
        }

        const user = await this.prisma.user.findUniqueOrThrow({
            where: { id: connection.userId },
            select: {
                id: true,
                finicityCustomerId: true,
            },
        })

        if (!user.finicityCustomerId) {
            throw new Error(`user ${user.id} is missing finicityCustomerId`)
        }

        const transactionsDateRange = {
            start: DateTime.now().minus(FinicityUtil.FINICITY_WINDOW_MAX),
            end: DateTime.now(),
        }

        const accounts = await this._extractAccounts(
            user.finicityCustomerId,
            connection.finicityInstitutionLoginId
        )

        const transactions = await this._extractTransactions(
            user.finicityCustomerId,
            accounts.map((a) => a.id),
            transactionsDateRange
        )

        this.logger.info(
            `Extracted Finicity data for customer ${user.finicityCustomerId} accounts=${accounts.length} transactions=${transactions.length}`,
            { connection: connection.id, transactionsDateRange }
        )

        return {
            accounts,
            transactions,
            transactionsDateRange,
        }
    }

    transform(
        connection: Connection,
        { accounts, transactions, transactionsDateRange }: FinicityRawData
    ): Promise<FinicityData> {
        const positions = accounts.flatMap(
            (a) =>
                a.position
                    ?.filter((p) => p.securityId != null || p.symbol != null)
                    .map((p) => ({
                        ...p,
                        accountId: a.id,
                        marketValue: p.marketValue ? +p.marketValue || 0 : 0,
                        security: {
                            ...getSecurityIdAndType(p)!,
                            securityName: p.securityName ?? p.fundName,
                            symbol: p.symbol,
                            currentPrice: p.currentPrice,
                            currentPriceDate: p.currentPriceDate,
                            type: p.securityType,
                            assetClass: p.assetClass,
                            fiAssetClass: p.fiAssetClass,
                        },
                    })) ?? []
        )

        const [_investmentTransactions, _transactions] = _(transactions)
            .uniqBy((t) => t.id)
            .partition((t) => isInvestmentTransaction(t))
            .value()

        this.logger.info(
            `Transformed Finicity transactions positions=${positions.length} transactions=${_transactions.length} investment_transactions=${_investmentTransactions.length}`,
            { connection: connection.id }
        )

        return Promise.resolve<FinicityData>({
            accounts,
            positions,
            transactions: _transactions,
            transactionsDateRange,
            investmentTransactions: _investmentTransactions.map((it) => {
                const security = getSecurityIdAndType(it)
                return {
                    ...it,
                    security: security
                        ? {
                              ...security,
                              symbol: it.symbol || it.ticker,
                          }
                        : null,
                }
            }),
            investmentTransactionsDateRange: transactionsDateRange,
        })
    }

    async load(connection: Connection, data: FinicityData): Promise<void> {
        await this.prisma.$transaction([
            ...this._loadAccounts(connection, data),
            ...this._loadPositions(connection, data),
            ...this._loadTransactions(connection, data),
            ...this._loadInvestmentTransactions(connection, data),
        ])

        this.logger.info(`Loaded Finicity data for connection ${connection.id}`, {
            connection: connection.id,
        })
    }

    private async _extractAccounts(customerId: string, institutionLoginId: string) {
        const { accounts } = await this.finicity.getCustomerAccounts({ customerId })

        return accounts.filter(
            (a) => a.institutionLoginId.toString() === institutionLoginId && a.currency === 'USD'
        )
    }

    private _loadAccounts(connection: Connection, { accounts }: Pick<FinicityData, 'accounts'>) {
        return [
            // upsert accounts
            ...accounts.map((finicityAccount) => {
                const type = FinicityUtil.getType(finicityAccount)
                const classification = AccountUtil.getClassification(type)

                return this.prisma.account.upsert({
                    where: {
                        accountConnectionId_finicityAccountId: {
                            accountConnectionId: connection.id,
                            finicityAccountId: finicityAccount.id,
                        },
                    },
                    create: {
                        accountConnectionId: connection.id,
                        finicityAccountId: finicityAccount.id,
                        type: FinicityUtil.getType(finicityAccount),
                        provider: 'finicity',
                        categoryProvider: FinicityUtil.getAccountCategory(finicityAccount),
                        subcategoryProvider: finicityAccount.type,
                        name: finicityAccount.name,
                        mask: finicityAccount.accountNumberDisplay,
                        finicityType: finicityAccount.type,
                        finicityDetail: finicityAccount.detail,
                        ...FinicityUtil.getAccountBalanceData(finicityAccount, classification),
                    },
                    update: {
                        type: FinicityUtil.getType(finicityAccount),
                        categoryProvider: FinicityUtil.getAccountCategory(finicityAccount),
                        subcategoryProvider: finicityAccount.type,
                        finicityType: finicityAccount.type,
                        finicityDetail: finicityAccount.detail,
                        ..._.omit(
                            FinicityUtil.getAccountBalanceData(finicityAccount, classification),
                            ['currentBalanceStrategy', 'availableBalanceStrategy']
                        ),
                    },
                })
            }),
            // any accounts that are no longer in Finicity should be marked inactive
            this.prisma.account.updateMany({
                where: {
                    accountConnectionId: connection.id,
                    AND: [
                        { finicityAccountId: { not: null } },
                        { finicityAccountId: { notIn: accounts.map((a) => a.id) } },
                    ],
                },
                data: {
                    isActive: false,
                },
            }),
        ]
    }

    private _loadPositions(connection: Connection, { positions }: Pick<FinicityData, 'positions'>) {
        const securities = _(positions)
            .map((p) => p.security)
            .uniqBy((s) => getSecurityId(s))
            .value()

        const securitiesWithPrices = securities.filter((s) => s.currentPrice != null)

        return [
            ...(securities.length > 0
                ? [
                      // upsert securities
                      this.prisma.$executeRaw`
                        INSERT INTO security (finicity_security_id, finicity_security_id_type, name, symbol, finicity_type, finicity_asset_class, finicity_fi_asset_class)
                        VALUES
                          ${Prisma.join(
                              securities.map(
                                  ({
                                      securityId,
                                      securityIdType,
                                      securityName,
                                      symbol,
                                      type,
                                      assetClass,
                                      fiAssetClass,
                                  }) =>
                                      Prisma.sql`(
                                        ${securityId},
                                        ${securityIdType},
                                        ${securityName},
                                        ${symbol},
                                        ${type},
                                        ${assetClass},
                                        ${fiAssetClass}
                                      )`
                              )
                          )}
                        ON CONFLICT (finicity_security_id, finicity_security_id_type) DO UPDATE
                        SET
                          name = EXCLUDED.name,
                          symbol = EXCLUDED.symbol,
                          finicity_type = EXCLUDED.finicity_type,
                          finicity_asset_class = EXCLUDED.finicity_asset_class,
                          finicity_fi_asset_class = EXCLUDED.finicity_fi_asset_class
                      `,
                  ]
                : []),
            ...(securitiesWithPrices.length > 0
                ? [
                      // upsert security prices
                      this.prisma.$executeRaw`
                        INSERT INTO security_pricing (security_id, date, price_close, source)
                        VALUES
                          ${Prisma.join(
                              securitiesWithPrices.map(
                                  ({
                                      securityId,
                                      securityIdType,
                                      currentPrice,
                                      currentPriceDate,
                                  }) =>
                                      Prisma.sql`(
                                        (SELECT id FROM security WHERE finicity_security_id = ${securityId} AND finicity_security_id_type = ${securityIdType}),
                                        ${
                                            currentPriceDate
                                                ? DateTime.fromSeconds(currentPriceDate, {
                                                      zone: 'utc',
                                                  }).toISODate()
                                                : DateTime.now().toISODate()
                                        }::date,
                                        ${currentPrice},
                                        'finicity'
                                      )`
                              )
                          )}
                        ON CONFLICT DO NOTHING
                      `,
                  ]
                : []),
            ...(positions.length > 0
                ? [
                      // upsert holdings
                      this.prisma.$executeRaw`
                        INSERT INTO holding (finicity_position_id, account_id, security_id, value, quantity, cost_basis_provider, currency_code)
                        VALUES
                          ${Prisma.join(
                              // de-dupe positions in case Finicity returns duplicate account/security pairs (they do for test accounts)
                              _.uniqBy(
                                  positions,
                                  (p) => `${p.accountId}.${getSecurityId(p.security)}`
                              ).map(
                                  ({
                                      id,
                                      accountId,
                                      security: { securityId, securityIdType },
                                      units,
                                      quantity,
                                      marketValue,
                                      costBasis,
                                  }) =>
                                      Prisma.sql`(
                                          ${id},
                                          (SELECT id FROM account WHERE account_connection_id = ${
                                              connection.id
                                          } AND finicity_account_id = ${accountId}),
                                          (SELECT id FROM security WHERE finicity_security_id = ${securityId} AND finicity_security_id_type = ${securityIdType}),
                                          ${marketValue || 0},
                                          ${units ?? quantity ?? 0},
                                          ${costBasis},
                                          ${'USD'}
                                      )`
                              )
                          )}
                        ON CONFLICT (finicity_position_id) DO UPDATE
                        SET
                          account_id = EXCLUDED.account_id,
                          security_id = EXCLUDED.security_id,
                          value = EXCLUDED.value,
                          quantity = EXCLUDED.quantity,
                          cost_basis_provider = EXCLUDED.cost_basis_provider,
                          currency_code = EXCLUDED.currency_code;
                      `,
                  ]
                : []),
            // Any holdings that are no longer in Finicity should be deleted
            this.prisma.holding.deleteMany({
                where: {
                    account: {
                        accountConnectionId: connection.id,
                    },
                    AND: [
                        { finicityPositionId: { not: null } },
                        {
                            finicityPositionId: {
                                notIn: positions
                                    .map((p) => p.id?.toString())
                                    .filter((id): id is string => id != null),
                            },
                        },
                    ],
                },
            }),
        ]
    }

    private async _extractTransactions(
        customerId: string,
        accountIds: string[],
        dateRange: SharedType.DateRange<DateTime>
    ) {
        const accountTransactions = await Promise.all(
            accountIds.map((accountId) =>
                SharedUtil.paginate({
                    pageSize: 1000, // https://api-reference.finicity.com/#/rest/api-endpoints/transactions/get-customer-account-transactions
                    fetchData: async (offset, count) => {
                        const { transactions } = await SharedUtil.withRetry(
                            () =>
                                this.finicity.getAccountTransactions({
                                    customerId,
                                    accountId,
                                    fromDate: dateRange.start.toUnixInteger(),
                                    toDate: dateRange.end.toUnixInteger(),
                                    start: offset + 1, // finicity uses 1-based indexing
                                    limit: count,
                                }),
                            {
                                maxRetries: 3,
                            }
                        )

                        return transactions
                    },
                })
            )
        )

        return accountTransactions.flat()
    }

    private _loadTransactions(
        connection: Connection,
        {
            transactions,
            transactionsDateRange,
        }: Pick<FinicityData, 'transactions' | 'transactionsDateRange'>
    ) {
        if (!transactions.length) return []

        const txnUpsertQueries = _.chunk(transactions, 1_000).map((chunk) => {
            return this.prisma.$executeRaw`
                INSERT INTO transaction (account_id, finicity_transaction_id, date, name, amount, pending, currency_code, merchant_name, finicity_type, finicity_categorization)
                VALUES
                    ${Prisma.join(
                        chunk.map((finicityTransaction) => {
                            const {
                                id,
                                accountId,
                                description,
                                memo,
                                amount,
                                status,
                                type,
                                categorization,
                                transactionDate,
                                postedDate,
                                currencySymbol,
                            } = finicityTransaction

                            return Prisma.sql`(
                                (SELECT id FROM account WHERE account_connection_id = ${
                                    connection.id
                                } AND finicity_account_id = ${accountId.toString()}),
                                ${id},
                                ${DateTime.fromSeconds(transactionDate ?? postedDate, {
                                    zone: 'utc',
                                }).toISODate()}::date,
                                ${[description, memo].filter(Boolean).join(' ')},
                                ${DbUtil.toDecimal(-amount)},
                                ${status === 'pending'},
                                ${currencySymbol || 'USD'},
                                ${categorization?.normalizedPayeeName},
                                ${type},
                                ${categorization}
                            )`
                        })
                    )}
                ON CONFLICT (finicity_transaction_id) DO UPDATE
                SET
                    name = EXCLUDED.name,
                    amount = EXCLUDED.amount,
                    pending = EXCLUDED.pending,
                    merchant_name = EXCLUDED.merchant_name,
                    finicity_type = EXCLUDED.finicity_type,
                    finicity_categorization = EXCLUDED.finicity_categorization;
            `
        })

        return [
            // upsert transactions
            ...txnUpsertQueries,
            // delete finicity-specific transactions that are no longer in finicity
            this.prisma.transaction.deleteMany({
                where: {
                    account: {
                        accountConnectionId: connection.id,
                    },
                    AND: [
                        { finicityTransactionId: { not: null } },
                        { finicityTransactionId: { notIn: transactions.map((t) => `${t.id}`) } },
                    ],
                    date: {
                        gte: transactionsDateRange.start.startOf('day').toJSDate(),
                        lte: transactionsDateRange.end.endOf('day').toJSDate(),
                    },
                },
            }),
        ]
    }

    private _loadInvestmentTransactions(
        connection: Connection,
        {
            investmentTransactions,
            investmentTransactionsDateRange,
        }: Pick<FinicityData, 'investmentTransactions' | 'investmentTransactionsDateRange'>
    ) {
        if (!investmentTransactions.length) return []

        const securities = _(investmentTransactions)
            .map((p) => p.security)
            .filter(SharedUtil.nonNull)
            .uniqBy((s) => getSecurityId(s))
            .value()

        return [
            // upsert securities
            ...(securities.length > 0
                ? [
                      this.prisma.$executeRaw`
                        INSERT INTO security (finicity_security_id, finicity_security_id_type, symbol)
                        VALUES
                          ${Prisma.join(
                              securities.map((s) => {
                                  return Prisma.sql`(
                                    ${s.securityId},
                                    ${s.securityIdType},
                                    ${s.symbol}
                                  )`
                              })
                          )}
                        ON CONFLICT DO NOTHING;
                      `,
                  ]
                : []),

            // upsert investment transactions
            ..._.chunk(investmentTransactions, 1_000).map((chunk) => {
                return this.prisma.$executeRaw`
                  INSERT INTO investment_transaction (account_id, security_id, finicity_transaction_id, date, name, amount, fees, quantity, price, currency_code, finicity_investment_transaction_type)
                  VALUES
                      ${Prisma.join(
                          chunk.map((t) => {
                              const {
                                  id,
                                  accountId,
                                  amount,
                                  feeAmount,
                                  description,
                                  memo,
                                  unitQuantity,
                                  unitPrice,
                                  transactionDate,
                                  postedDate,
                                  currencySymbol,
                                  investmentTransactionType,
                                  security,
                              } = t

                              return Prisma.sql`(
                                (SELECT id FROM account WHERE account_connection_id = ${
                                    connection.id
                                } AND finicity_account_id = ${accountId.toString()}),
                                ${
                                    security
                                        ? Prisma.sql`(SELECT id FROM security WHERE finicity_security_id = ${security.securityId} AND finicity_security_id_type = ${security.securityIdType})`
                                        : null
                                },
                                ${id},
                                ${DateTime.fromSeconds(transactionDate ?? postedDate, {
                                    zone: 'utc',
                                }).toISODate()}::date,
                                ${[description, memo].filter(Boolean).join(' ')},
                                ${DbUtil.toDecimal(-amount)},
                                ${DbUtil.toDecimal(feeAmount)},
                                ${DbUtil.toDecimal(unitQuantity ?? 0)},
                                ${DbUtil.toDecimal(unitPrice ?? 0)},
                                ${currencySymbol || 'USD'},
                                ${investmentTransactionType}
                            )`
                          })
                      )}
                  ON CONFLICT (finicity_transaction_id) DO UPDATE
                  SET
                    account_id = EXCLUDED.account_id,
                    security_id = EXCLUDED.security_id,
                    date = EXCLUDED.date,
                    name = EXCLUDED.name,
                    amount = EXCLUDED.amount,
                    fees = EXCLUDED.fees,
                    quantity = EXCLUDED.quantity,
                    price = EXCLUDED.price,
                    currency_code = EXCLUDED.currency_code,
                    finicity_investment_transaction_type = EXCLUDED.finicity_investment_transaction_type;
                `
            }),

            // delete finicity-specific investment transactions that are no longer in finicity
            this.prisma.investmentTransaction.deleteMany({
                where: {
                    account: {
                        accountConnectionId: connection.id,
                    },
                    AND: [
                        { finicityTransactionId: { not: null } },
                        {
                            finicityTransactionId: {
                                notIn: investmentTransactions.map((t) => `${t.id}`),
                            },
                        },
                    ],
                    date: {
                        gte: investmentTransactionsDateRange.start.startOf('day').toJSDate(),
                        lte: investmentTransactionsDateRange.end.endOf('day').toJSDate(),
                    },
                },
            }),
        ]
    }
}
