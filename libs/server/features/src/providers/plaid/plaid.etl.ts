import type { AccountConnection, PrismaClient } from '@prisma/client'
import type { Logger } from 'winston'
import type { IMarketDataService, IETL, ICryptoService } from '@maybe-finance/server/shared'
import { DbUtil } from '@maybe-finance/server/shared'
import type { SharedType } from '@maybe-finance/shared'
import { MarketUtil } from '@maybe-finance/shared'
import type {
    AccountBase as PlaidAccount,
    Transaction as PlaidTransaction,
    InvestmentTransaction as PlaidInvestmentTransaction,
    Security as PlaidSecurity,
    Holding as PlaidHolding,
    Item as PlaidItem,
    LiabilitiesObject as PlaidLiabilities,
    PlaidApi,
} from 'plaid'
import { InvestmentTransactionSubtype, InvestmentTransactionType } from 'plaid'
import { Prisma, InvestmentTransactionCategory } from '@prisma/client'
import { DateTime } from 'luxon'
import _, { chunk } from 'lodash'
import { ErrorUtil, PlaidUtil } from '@maybe-finance/server/shared'
import { SharedUtil } from '@maybe-finance/shared'

export type PlaidRawData = {
    item: Pick<PlaidItem, 'error' | 'consent_expiration_time'>
    accounts: Pick<PlaidAccount, 'account_id' | 'type' | 'subtype' | 'name' | 'mask' | 'balances'>[]
    transactions: Pick<
        PlaidTransaction,
        | 'transaction_id'
        | 'account_id'
        | 'name'
        | 'amount'
        | 'pending'
        | 'date'
        | 'merchant_name'
        | 'category'
        | 'category_id'
        | 'personal_finance_category'
        | 'iso_currency_code'
        | 'unofficial_currency_code'
    >[]
    transactionsDateRange: SharedType.DateRange
    investmentTransactions: (Pick<
        PlaidInvestmentTransaction,
        | 'investment_transaction_id'
        | 'account_id'
        | 'security_id'
        | 'name'
        | 'amount'
        | 'fees'
        | 'quantity'
        | 'date'
        | 'price'
        | 'type'
        | 'subtype'
        | 'iso_currency_code'
        | 'unofficial_currency_code'
    > & {
        security: Pick<
            PlaidSecurity,
            | 'security_id'
            | 'name'
            | 'ticker_symbol'
            | 'cusip'
            | 'isin'
            | 'type'
            | 'iso_currency_code'
            | 'unofficial_currency_code'
            | 'is_cash_equivalent'
        > | null
        account: PlaidRawData['accounts'][0] | null
    })[]
    investmentTransactionsDateRange: SharedType.DateRange
    holdings: (Pick<
        PlaidHolding,
        | 'account_id'
        | 'security_id'
        | 'quantity'
        | 'cost_basis'
        | 'institution_value'
        | 'institution_price_as_of'
        | 'iso_currency_code'
        | 'unofficial_currency_code'
    > & {
        security: Pick<
            PlaidSecurity,
            | 'security_id'
            | 'name'
            | 'ticker_symbol'
            | 'cusip'
            | 'isin'
            | 'type'
            | 'close_price'
            | 'close_price_as_of'
            | 'iso_currency_code'
            | 'unofficial_currency_code'
            | 'is_cash_equivalent'
        > | null
        account: PlaidRawData['accounts'][0] | null
    })[]
    liabilities: PlaidLiabilities
}

type PlaidData = PlaidRawData

const isPlaidErrorIgnorable = (err: any) =>
    ErrorUtil.isPlaidError(err) &&
    err.response.data.error_type === 'ITEM_ERROR' &&
    [
        'PRODUCTS_NOT_SUPPORTED',
        'PRODUCT_NOT_READY',
        'NO_ACCOUNTS',
        'NO_AUTH_ACCOUNTS',
        'NO_INVESTMENT_ACCOUNTS',
        'NO_INVESTMENT_AUTH_ACCOUNTS',
        'NO_LIABILITY_ACCOUNTS',
    ].includes(err.response.data.error_code)

type Connection = Pick<AccountConnection, 'id' | 'plaidAccessToken'>

function getSecurityTickerData({
    type,
    ticker_symbol,
    cusip,
    isin,
}: Pick<PlaidSecurity, 'type' | 'ticker_symbol' | 'cusip' | 'isin'>): Pick<
    PlaidSecurity,
    'ticker_symbol' | 'cusip' | 'isin'
> {
    if (ticker_symbol != null && type != null && ['equity', 'etf'].includes(type)) {
        const underlyingTicker = MarketUtil.getUnderlyingTicker(ticker_symbol)
        if (underlyingTicker) {
            return { ticker_symbol: underlyingTicker, cusip: null, isin: null }
        }
    }

    return { ticker_symbol, cusip, isin }
}

export class PlaidETL implements IETL<Connection, PlaidRawData, PlaidData> {
    public constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly plaid: Pick<
            PlaidApi,
            | 'accountsGet'
            | 'transactionsGet'
            | 'investmentsTransactionsGet'
            | 'investmentsHoldingsGet'
            | 'liabilitiesGet'
        >,
        private readonly crypto: ICryptoService,
        private readonly marketData: Pick<IMarketDataService, 'getOptionDetails'>
    ) {}

    async extract(connection: Connection): Promise<PlaidData> {
        if (!connection.plaidAccessToken) {
            throw new Error(`no plaid access token for connection ${connection.id}`)
        }

        const accessToken = this.crypto.decrypt(connection.plaidAccessToken)

        const transactionsDateRange = {
            start: DateTime.now().minus(PlaidUtil.PLAID_WINDOW_MAX).toISODate(),
            end: DateTime.now().toISODate(),
        }

        const investmentTransactionsDateRange = {
            start: DateTime.now().minus(PlaidUtil.PLAID_WINDOW_MAX).toISODate(),
            end: DateTime.now().toISODate(),
        }

        const [{ item, accounts }, transactions, investmentTransactions, holdings, liabilities] =
            await Promise.all([
                this._extractAccounts(accessToken),
                this._extractTransactions(accessToken, transactionsDateRange),
                this._extractInvestmentTransactions(accessToken, investmentTransactionsDateRange),
                this._extractHoldings(accessToken),
                this._extractLiabilities(accessToken),
            ])

        this.logger.info(
            `Extracted Plaid data for item ${item.item_id} accounts=${
                accounts.length
            } transactions=${transactions.length} investmentTransactions=${
                investmentTransactions.length
            } holdings=${holdings.length} liabilities=${
                (liabilities.credit?.length ?? 0) +
                (liabilities.mortgage?.length ?? 0) +
                (liabilities.student?.length ?? 0)
            }`,
            { connection: connection.id, transactionsDateRange, investmentTransactionsDateRange }
        )

        return {
            item,
            accounts: accounts.filter((a) => a.balances.iso_currency_code === 'USD'),
            transactions,
            transactionsDateRange,
            investmentTransactions,
            investmentTransactionsDateRange,
            holdings,
            liabilities,
        }
    }

    async transform(_connection: Connection, data: PlaidData): Promise<PlaidData> {
        return {
            ...data,
            investmentTransactions: data.investmentTransactions.map((it) => ({
                ...it,
                security: it.security
                    ? {
                          ...it.security,
                          ...getSecurityTickerData(it.security),
                      }
                    : null,
            })),
            holdings: data.holdings.map((h) => ({
                ...h,
                security: h.security
                    ? {
                          ...h.security,
                          ...getSecurityTickerData(h.security),
                      }
                    : null,
            })),
        }
    }

    async load(connection: Connection, data: PlaidData): Promise<void> {
        await this.prisma.$transaction([
            ...this._loadAccounts(connection, data),
            ...this._loadTransactions(connection, data),
            ...this._loadInvestmentTransactions(connection, data),
            ...(await this._loadHoldings(connection, data)),
            ...this._loadLiabilities(connection, data),
            // update connection status
            this.prisma.accountConnection.update({
                where: { id: connection.id },
                data: {
                    plaidConsentExpiration: data.item.consent_expiration_time,
                    ...(data.item.error && {
                        status: 'ERROR',
                        plaidError: data.item.error as any,
                    }),
                },
            }),
        ])

        this.logger.info(`Loaded plaid data for connection ${connection.id}`, {
            connection: connection.id,
        })
    }

    private async _extractAccounts(accessToken: string) {
        const { data } = await this.plaid.accountsGet({
            access_token: accessToken,
        })

        return { item: data.item, accounts: data.accounts }
    }

    private _loadAccounts(connection: Connection, { accounts }: Pick<PlaidData, 'accounts'>) {
        return [
            // upsert accounts
            ...accounts.map((plaidAccount) => {
                return this.prisma.account.upsert({
                    where: {
                        accountConnectionId_plaidAccountId: {
                            accountConnectionId: connection.id,
                            plaidAccountId: plaidAccount.account_id,
                        },
                    },
                    create: {
                        type: PlaidUtil.getType(plaidAccount.type),
                        provider: 'plaid',
                        categoryProvider: PlaidUtil.plaidTypesToCategory(plaidAccount.type),
                        subcategoryProvider: plaidAccount.subtype ?? 'other',
                        accountConnectionId: connection.id,
                        plaidAccountId: plaidAccount.account_id,
                        name: plaidAccount.name,
                        plaidType: plaidAccount.type,
                        plaidSubtype: plaidAccount.subtype,
                        mask: plaidAccount.mask,
                        ...PlaidUtil.getAccountBalanceData(
                            plaidAccount.balances,
                            plaidAccount.type
                        ),
                    },
                    update: {
                        type: PlaidUtil.getType(plaidAccount.type),
                        categoryProvider: PlaidUtil.plaidTypesToCategory(plaidAccount.type),
                        subcategoryProvider: plaidAccount.subtype ?? 'other',
                        plaidType: plaidAccount.type,
                        plaidSubtype: plaidAccount.subtype,
                        ..._.omit(
                            PlaidUtil.getAccountBalanceData(
                                plaidAccount.balances,
                                plaidAccount.type
                            ),
                            ['currentBalanceStrategy', 'availableBalanceStrategy']
                        ),
                    },
                })
            }),
            // any accounts that are no longer in Plaid should be marked inactive
            this.prisma.account.updateMany({
                where: {
                    accountConnectionId: connection.id,
                    AND: [
                        { plaidAccountId: { not: null } },
                        { plaidAccountId: { notIn: accounts.map((a) => a.account_id) } },
                    ],
                },
                data: {
                    isActive: false,
                },
            }),
        ]
    }

    private _extractTransactions(accessToken: string, dateRange: SharedType.DateRange) {
        return SharedUtil.paginate({
            pageSize: 500, // https://plaid.com/docs/api/products/transactions/#transactions-get-request-options-count
            fetchData: async (offset, count) => {
                try {
                    const { data } = await SharedUtil.withRetry(
                        () =>
                            this.plaid.transactionsGet({
                                access_token: accessToken,
                                start_date: dateRange.start,
                                end_date: dateRange.end,
                                options: {
                                    offset,
                                    count,
                                    include_personal_finance_category: true,
                                },
                            }),
                        {
                            maxRetries: 3,
                            onError: (err) =>
                                !ErrorUtil.isPlaidError(err) || err.response.status >= 500,
                        }
                    )

                    return data.transactions
                } catch (err) {
                    if (isPlaidErrorIgnorable(err)) {
                        return []
                    }

                    throw err
                }
            },
        })
    }

    private _loadTransactions(
        connection: Connection,
        {
            transactions,
            transactionsDateRange,
        }: Pick<PlaidData, 'transactions' | 'transactionsDateRange'>
    ) {
        if (!transactions.length) return []

        const txnUpsertQueries = chunk(transactions, 1_000).map((chunk) => {
            return this.prisma.$executeRaw`
                INSERT INTO transaction (account_id, plaid_transaction_id, date, name, amount, pending, currency_code, merchant_name, plaid_category, plaid_category_id, plaid_personal_finance_category)
                VALUES
                    ${Prisma.join(
                        chunk.map((plaidTransaction) => {
                            const {
                                account_id,
                                transaction_id,
                                name,
                                amount,
                                pending,
                                date,
                                merchant_name,
                                category,
                                category_id,
                                personal_finance_category,
                                iso_currency_code,
                                unofficial_currency_code,
                            } = plaidTransaction

                            const currencyCode =
                                iso_currency_code || unofficial_currency_code || 'USD'

                            return Prisma.sql`(
                                (SELECT id FROM account WHERE account_connection_id = ${
                                    connection.id
                                } AND plaid_account_id = ${account_id}),
                                ${transaction_id},
                                ${date}::date,
                                ${name},
                                ${DbUtil.toDecimal(amount)},
                                ${pending},
                                ${currencyCode},
                                ${merchant_name},
                                ${category ?? []},
                                ${category_id},
                                ${personal_finance_category}
                            )`
                        })
                    )}
                ON CONFLICT (plaid_transaction_id) DO UPDATE
                SET
                    name = EXCLUDED.name,
                    amount = EXCLUDED.amount,
                    pending = EXCLUDED.pending,
                    merchant_name = EXCLUDED.merchant_name,
                    plaid_category = EXCLUDED.plaid_category,
                    plaid_category_id = EXCLUDED.plaid_category_id,
                    plaid_personal_finance_category = EXCLUDED.plaid_personal_finance_category;
            `
        })

        return [
            ...txnUpsertQueries,
            // delete plaid-specific transactions that are no longer in plaid
            this.prisma.transaction.deleteMany({
                where: {
                    account: {
                        accountConnectionId: connection.id,
                    },
                    AND: [
                        { plaidTransactionId: { not: null } },
                        {
                            plaidTransactionId: {
                                notIn: transactions.map((t) => t.transaction_id),
                            },
                        },
                    ],
                    date: {
                        gte: DateTime.fromISO(transactionsDateRange.start)
                            .startOf('day')
                            .toJSDate(),
                        lte: DateTime.fromISO(transactionsDateRange.end).endOf('day').toJSDate(),
                    },
                },
            }),
        ]
    }

    private _extractInvestmentTransactions(accessToken: string, dateRange: SharedType.DateRange) {
        return SharedUtil.paginate({
            pageSize: 500, // https://plaid.com/docs/api/products/investments/#investments-transactions-get-request-options-count
            fetchData: async (offset, count) => {
                try {
                    const { data } = await SharedUtil.withRetry(
                        () =>
                            this.plaid.investmentsTransactionsGet({
                                access_token: accessToken,
                                start_date: dateRange.start,
                                end_date: dateRange.end,
                                options: {
                                    offset,
                                    count,
                                },
                            }),
                        {
                            maxRetries: 3,
                            onError: (err) =>
                                !ErrorUtil.isPlaidError(err) || err.response.status >= 500,
                        }
                    )

                    return data.investment_transactions.map((it) => ({
                        ...it,
                        security:
                            data.securities.find((s) => s.security_id === it.security_id) ?? null,
                        account: data.accounts.find((a) => a.account_id === it.account_id)!,
                    }))
                } catch (err) {
                    if (isPlaidErrorIgnorable(err)) {
                        return []
                    }

                    throw err
                }
            },
        })
    }

    private _loadInvestmentTransactions(
        connection: Connection,
        {
            investmentTransactions,
            investmentTransactionsDateRange,
        }: Pick<PlaidData, 'investmentTransactions' | 'investmentTransactionsDateRange'>
    ) {
        if (!investmentTransactions.length) return []

        const securities = _(investmentTransactions)
            .map((it) => it.security)
            .filter(SharedUtil.nonNull)
            .uniqBy((s) => s.security_id)
            .value()
        const accounts = investmentTransactions.map((it) => it.account!)

        return [
            ...(securities.length > 0
                ? [
                      // upsert securities
                      this.prisma.$executeRaw`
                        INSERT INTO security (plaid_security_id, name, symbol, cusip, isin, currency_code, plaid_type, plaid_is_cash_equivalent)
                        VALUES
                          ${Prisma.join(
                              securities.map(
                                  ({
                                      security_id,
                                      name,
                                      ticker_symbol,
                                      cusip,
                                      isin,
                                      iso_currency_code,
                                      unofficial_currency_code,
                                      type,
                                      is_cash_equivalent,
                                  }) =>
                                      Prisma.sql`(
                                        ${security_id},
                                        ${name},
                                        ${ticker_symbol},
                                        ${cusip},
                                        ${isin},
                                        ${iso_currency_code || unofficial_currency_code || 'USD'},
                                        ${type},
                                        ${is_cash_equivalent}
                                      )`
                              )
                          )}
                        ON CONFLICT (plaid_security_id) DO UPDATE
                        SET
                          name = EXCLUDED.name,
                          symbol = EXCLUDED.symbol,
                          cusip = EXCLUDED.cusip,
                          isin = EXCLUDED.isin,
                          currency_code = EXCLUDED.currency_code,
                          plaid_type = EXCLUDED.plaid_type;
                      `,
                  ]
                : []),

            // Insert inv transactions
            ...chunk(investmentTransactions, 1_000).map(
                (chunk) =>
                    this.prisma.$executeRaw`
                      INSERT INTO investment_transaction (account_id, security_id, plaid_investment_transaction_id, date, name, amount, fees, quantity, price, currency_code, plaid_type, plaid_subtype, category)
                      VALUES
                          ${Prisma.join(
                              chunk.map(
                                  ({
                                      account_id,
                                      security_id,
                                      investment_transaction_id,
                                      name,
                                      amount,
                                      fees,
                                      quantity,
                                      date,
                                      price,
                                      iso_currency_code,
                                      unofficial_currency_code,
                                      type,
                                      subtype,
                                  }) => {
                                      const currencyCode =
                                          iso_currency_code || unofficial_currency_code || 'USD'

                                      return Prisma.sql`(
                                        (SELECT id FROM account WHERE account_connection_id = ${
                                            connection.id
                                        } AND plaid_account_id = ${account_id}),
                                        (SELECT id FROM security WHERE plaid_security_id = ${security_id}),
                                        ${investment_transaction_id},
                                        ${date}::date,
                                        ${name},
                                        ${DbUtil.toDecimal(amount)},
                                        ${DbUtil.toDecimal(fees)},
                                        ${DbUtil.toDecimal(quantity)},
                                        ${DbUtil.toDecimal(price)},
                                        ${currencyCode},
                                        ${type},
                                        ${subtype},
                                        ${this.getInvestmentTransactionCategoryByPlaidType(
                                            type,
                                            subtype
                                        )}
                                      )`
                                  }
                              )
                          )}
                      ON CONFLICT (plaid_investment_transaction_id) DO UPDATE
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
                        plaid_type = EXCLUDED.plaid_type,
                        plaid_subtype = EXCLUDED.plaid_subtype;
                        category = EXCLUDED.category;
                    `
            ),

            // delete plaid-specific investment transactions that are no longer in plaid
            this.prisma.investmentTransaction.deleteMany({
                where: {
                    account: {
                        accountConnectionId: connection.id,
                    },
                    AND: [
                        {
                            plaidInvestmentTransactionId: { not: null },
                        },
                        {
                            plaidInvestmentTransactionId: {
                                notIn: investmentTransactions.map(
                                    (it) => it.investment_transaction_id
                                ),
                            },
                        },
                    ],
                    date: {
                        gte: DateTime.fromISO(investmentTransactionsDateRange.start)
                            .startOf('day')
                            .toJSDate(),
                        lte: DateTime.fromISO(investmentTransactionsDateRange.end)
                            .endOf('day')
                            .toJSDate(),
                    },
                },
            }),
            // update account current/available balances
            ...(accounts.length > 0
                ? [
                      this.prisma.$executeRaw`
                        UPDATE account AS a
                        SET
                          current_balance_provider = u.current_balance_provider,
                          available_balance_provider = u.available_balance_provider,
                          currency_code = u.currency_code
                        FROM (
                          VALUES
                            ${Prisma.join(
                                accounts.map(({ account_id, balances, type }) => {
                                    const {
                                        currentBalanceProvider,
                                        availableBalanceProvider,
                                        currencyCode,
                                    } = PlaidUtil.getAccountBalanceData(balances, type)

                                    return Prisma.sql`(
                                      (SELECT id FROM account WHERE account_connection_id = ${connection.id} AND plaid_account_id = ${account_id}),
                                      ${currentBalanceProvider}::numeric,
                                      ${availableBalanceProvider}::numeric,
                                      ${currencyCode}
                                    )`
                                })
                            )}
                        ) AS u(id, current_balance_provider, available_balance_provider, currency_code)
                        WHERE
                          a.id = u.id;
                      `,
                  ]
                : []),
        ]
    }

    private getInvestmentTransactionCategoryByPlaidType = (
        type: InvestmentTransactionType,
        subType: InvestmentTransactionSubtype
    ): InvestmentTransactionCategory => {
        if (type === InvestmentTransactionType.Buy) {
            return InvestmentTransactionCategory.buy
        }

        if (type === InvestmentTransactionType.Sell) {
            return InvestmentTransactionCategory.sell
        }

        if (
            [
                InvestmentTransactionSubtype.Dividend,
                InvestmentTransactionSubtype.QualifiedDividend,
                InvestmentTransactionSubtype.NonQualifiedDividend,
            ].includes(subType)
        ) {
            return InvestmentTransactionCategory.dividend
        }

        if (
            [
                InvestmentTransactionSubtype.NonResidentTax,
                InvestmentTransactionSubtype.Tax,
                InvestmentTransactionSubtype.TaxWithheld,
            ].includes(subType)
        ) {
            return InvestmentTransactionCategory.tax
        }

        if (
            type === InvestmentTransactionType.Fee ||
            [
                InvestmentTransactionSubtype.AccountFee,
                InvestmentTransactionSubtype.LegalFee,
                InvestmentTransactionSubtype.ManagementFee,
                InvestmentTransactionSubtype.MarginExpense,
                InvestmentTransactionSubtype.TransferFee,
                InvestmentTransactionSubtype.TrustFee,
            ].includes(subType)
        ) {
            return InvestmentTransactionCategory.fee
        }

        if (type === InvestmentTransactionType.Cash) {
            return InvestmentTransactionCategory.transfer
        }

        if (type === InvestmentTransactionType.Cancel) {
            return InvestmentTransactionCategory.cancel
        }

        return InvestmentTransactionCategory.other
    }

    private async _extractHoldings(accessToken: string) {
        try {
            const { data } = await this.plaid.investmentsHoldingsGet({ access_token: accessToken })

            return data.holdings.map((h) => ({
                ...h,
                security: data.securities.find((s) => s.security_id === h.security_id)!,
                account: data.accounts.find((a) => a.account_id === h.account_id)!,
            }))
        } catch (err) {
            if (isPlaidErrorIgnorable(err)) {
                return []
            }

            throw err
        }
    }

    private async _loadHoldings(connection: Connection, { holdings }: Pick<PlaidData, 'holdings'>) {
        const securities = _(holdings)
            .filter((h) => !!h.security)
            .map((h) => h.security!)
            .uniqBy((s) => s.security_id)
            .value()

        const securitiesWithPrices = securities.filter((s) => s.close_price != null)

        // Fill security prices from holdings when Plaid doesn't provide them explicitly
        const holdingsWithSecurityPrices = holdings.filter(
            (h) =>
                !securitiesWithPrices.some((s) => s.security_id === h.security_id) && h.quantity > 0
        )

        // Gather options contract details from market data to determine shares per contract
        const optionsDetails = await Promise.all(
            securities
                .filter(
                    (security) => security.ticker_symbol != null && security.type === 'derivative'
                )
                .map(async ({ ticker_symbol: symbol }) => ({
                    symbol,
                    details: await this.marketData.getOptionDetails(symbol).catch(() => null),
                }))
        )

        const holdingsWithDerivedIds = PlaidUtil.getHoldingsWithDerivedIds(holdings)

        return [
            ...(securities.length > 0
                ? [
                      // upsert securities
                      this.prisma.$executeRaw`
                        INSERT INTO security (plaid_security_id, name, symbol, cusip, isin, shares_per_contract, currency_code, plaid_type, plaid_is_cash_equivalent)
                        VALUES
                          ${Prisma.join(
                              securities.map(
                                  ({
                                      security_id,
                                      name,
                                      ticker_symbol,
                                      cusip,
                                      isin,
                                      iso_currency_code,
                                      unofficial_currency_code,
                                      type,
                                      is_cash_equivalent,
                                  }) =>
                                      Prisma.sql`(
                                        ${security_id},
                                        ${name},
                                        ${ticker_symbol},
                                        ${cusip},
                                        ${isin},
                                        ${
                                            type === 'derivative'
                                                ? optionsDetails.find(
                                                      (od) => od.symbol === ticker_symbol
                                                  )?.details?.sharesPerContract ?? null
                                                : null
                                        },
                                        ${iso_currency_code || unofficial_currency_code || 'USD'},
                                        ${type},
                                        ${is_cash_equivalent}
                                      )`
                              )
                          )}
                        ON CONFLICT (plaid_security_id) DO UPDATE
                        SET
                          name = EXCLUDED.name,
                          symbol = EXCLUDED.symbol,
                          cusip = COALESCE(EXCLUDED.cusip, security.cusip),
                          isin = COALESCE(EXCLUDED.isin, security.isin),
                          shares_per_contract = COALESCE(EXCLUDED.shares_per_contract, security.shares_per_contract),
                          currency_code = EXCLUDED.currency_code,
                          plaid_type = EXCLUDED.plaid_type,
                          plaid_is_cash_equivalent = EXCLUDED.plaid_is_cash_equivalent
                      `,
                  ]
                : []),
            ...(securitiesWithPrices.length
                ? [
                      this.prisma.$executeRaw`
                        INSERT INTO security_pricing (security_id, date, price_close, source)
                        VALUES
                          ${Prisma.join(
                              securitiesWithPrices.map(
                                  ({ security_id, close_price, close_price_as_of }) =>
                                      Prisma.sql`(
                                          (SELECT id FROM security WHERE plaid_security_id = ${security_id}),
                                          ${close_price_as_of ?? DateTime.now().toISODate()}::date,
                                          ${close_price},
                                          'plaid'
                                      )`
                              )
                          )}
                        ON CONFLICT DO NOTHING
                    `,
                  ]
                : []),
            ...(holdingsWithSecurityPrices.length
                ? [
                      this.prisma.$executeRaw`
                        INSERT INTO security_pricing (security_id, date, price_close, source)
                        VALUES
                          ${Prisma.join(
                              holdingsWithSecurityPrices.map(
                                  ({
                                      security_id,
                                      institution_value,
                                      quantity,
                                      institution_price_as_of,
                                  }) =>
                                      Prisma.sql`(
                                        (SELECT id FROM security WHERE plaid_security_id = ${security_id}),
                                        ${
                                            institution_price_as_of ?? DateTime.now().toISODate()
                                        }::date,
                                        ${institution_value} / ${quantity}::numeric / COALESCE((SELECT shares_per_contract FROM security WHERE plaid_security_id = ${security_id}), 1),
                                        'plaid'
                                      )`
                              )
                          )}
                        ON CONFLICT DO NOTHING
                      `,
                  ]
                : []),
            ...(holdings.length > 0
                ? [
                      // upsert holdings
                      this.prisma.$executeRaw`
                        INSERT INTO holding (plaid_holding_id, account_id, security_id, value, quantity, cost_basis_provider, currency_code)
                        VALUES
                          ${Prisma.join(
                              holdingsWithDerivedIds.map(
                                  ({
                                      account_id,
                                      security_id,
                                      institution_value,
                                      quantity,
                                      cost_basis,
                                      iso_currency_code,
                                      unofficial_currency_code,
                                      derivedId,
                                  }) => {
                                      const currencyCode =
                                          iso_currency_code || unofficial_currency_code || 'USD'

                                      return Prisma.sql`(
                                          ${derivedId},
                                          (SELECT id FROM account WHERE account_connection_id = ${connection.id} AND plaid_account_id = ${account_id}),
                                          (SELECT id FROM security WHERE plaid_security_id = ${security_id}),
                                          ${institution_value},
                                          ${quantity},
                                          ${cost_basis},
                                          ${currencyCode}
                                      )`
                                  }
                              )
                          )}
                        ON CONFLICT (plaid_holding_id) DO UPDATE
                        SET
                          value = EXCLUDED.value,
                          quantity = EXCLUDED.quantity,
                          cost_basis_provider = EXCLUDED.cost_basis_provider,
                          currency_code = EXCLUDED.currency_code;
                      `,
                  ]
                : []),
            // any holdings that are no longer in Plaid should be deleted
            this.prisma.holding.deleteMany({
                where: {
                    account: {
                        accountConnectionId: connection.id,
                    },
                    AND: [
                        { plaidHoldingId: { not: null } },
                        {
                            plaidHoldingId: {
                                notIn: holdingsWithDerivedIds.map((h) => h.derivedId),
                            },
                        },
                    ],
                },
            }),
        ]
    }

    private async _extractLiabilities(accessToken: string) {
        try {
            const { data } = await this.plaid.liabilitiesGet({ access_token: accessToken })

            return data.liabilities
        } catch (err) {
            if (isPlaidErrorIgnorable(err)) {
                return { credit: null, mortgage: null, student: null } as PlaidLiabilities
            }

            throw err
        }
    }

    private _loadLiabilities(
        connection: Connection,
        { liabilities }: Pick<PlaidData, 'liabilities'>
    ) {
        return [
            ...(liabilities.credit ?? [])
                .filter((ccl) => !!ccl.account_id)
                .map((ccl) =>
                    this.prisma.account.update({
                        where: {
                            accountConnectionId_plaidAccountId: {
                                accountConnectionId: connection.id,
                                plaidAccountId: ccl.account_id!,
                            },
                        },
                        data: {
                            plaidLiability: { credit: ccl },
                            creditProvider: PlaidUtil.normalizeCreditData(ccl),
                        },
                    })
                ),
            ...(liabilities.mortgage ?? []).map((ml) => {
                const loan = PlaidUtil.normalizeMortgageData(ml)
                return this.prisma.account.update({
                    where: {
                        accountConnectionId_plaidAccountId: {
                            accountConnectionId: connection.id,
                            plaidAccountId: ml.account_id,
                        },
                    },
                    data: {
                        startDate: loan.originationDate
                            ? DateTime.fromISO(loan.originationDate, { zone: 'utc' }).toJSDate()
                            : undefined,
                        plaidLiability: { mortgage: ml },
                        loanProvider: loan,
                    },
                })
            }),
            ...(liabilities.student ?? [])
                .filter((sl) => !!sl.account_id)
                .map((sl) => {
                    const loan = PlaidUtil.normalizeStudentLoanData(sl)
                    return this.prisma.account.update({
                        where: {
                            accountConnectionId_plaidAccountId: {
                                accountConnectionId: connection.id,
                                plaidAccountId: sl.account_id!,
                            },
                        },
                        data: {
                            startDate: loan.originationDate
                                ? DateTime.fromISO(loan.originationDate, { zone: 'utc' }).toJSDate()
                                : undefined,
                            plaidLiability: { student: sl },
                            loanProvider: loan,
                        },
                    })
                }),
        ]
    }
}
