import type {
    User,
    Valuation,
    AccountCategory,
    AccountConnection,
    Account,
    AccountClassification,
} from '@prisma/client'
import { Prisma } from '@prisma/client'
import type { Logger } from 'winston'
import type { DateTime } from 'luxon'
import _ from 'lodash'
import type { SharedType } from '@maybe-finance/shared'
import type { PgService } from '@maybe-finance/server/shared'
import { raw, sql, DbUtil } from '@maybe-finance/server/shared'

type PaginationOptions = { page: number; pageSize: number }

type ValuationTrend = {
    date: string
    amount: Prisma.Decimal
    valuation_id: Valuation['id'] | null
    period_change: Prisma.Decimal | null
    period_change_pct: Prisma.Decimal | null
    total_change: Prisma.Decimal
    total_change_pct: Prisma.Decimal
}

type BalanceSeries = {
    account_id: Account['id']
    date: string
    balance: Prisma.Decimal
}

type ReturnSeries = {
    account_id: Account['id']
    date: string
    rate_of_return: Prisma.Decimal
    contributions: Prisma.Decimal
    contributions_period: Prisma.Decimal
}

type NetWorthSeries = {
    date: string
    netWorth: Prisma.Decimal
    assets: Prisma.Decimal
    liabilities: Prisma.Decimal
    categories: Partial<Record<AccountCategory, Prisma.Decimal>>
}

type AccountRollup = {
    date: string
    classification: Account['classification']
    category: Account['category'] | null
    id: Account['id'] | null
    balance: Prisma.Decimal
    rollup_pct: Prisma.Decimal
    total_pct: Prisma.Decimal
    grouping: 'classification' | 'category' | 'account'
    account:
        | (Pick<Account, 'id' | 'name' | 'mask' | 'syncStatus'> & {
              connection: Pick<AccountConnection, 'name' | 'syncStatus'> | null
          })
        | null
}

export interface IAccountQueryService {
    getHoldingsEnriched(
        accountId: Account['id'],
        options: PaginationOptions
    ): Promise<
        Array<
            SharedType.HoldingEnriched & {
                cost_basis_user: Prisma.Decimal | null
                cost_basis_provider: Prisma.Decimal | null
            }
        >
    >
    getValuationTrends(
        accountId: Account['id'],
        start?: DateTime,
        end?: DateTime
    ): Promise<ValuationTrend[]>
    getReturnSeries(
        accountId: Account['id'] | Account['id'][],
        start: string,
        end: string
    ): Promise<ReturnSeries[]>
    getBalanceSeries(
        accountId: Account['id'] | Account['id'][],
        start: string,
        end: string,
        interval: SharedType.TimeSeriesInterval
    ): Promise<BalanceSeries[]>
    getNetWorthSeries(
        id: { userId: User['id'] } | { accountIds: Account['id'][] },
        start: string,
        end: string,
        interval: SharedType.TimeSeriesInterval
    ): Promise<NetWorthSeries[]>
    getRollup(
        id: { accountId: Account['id'] } | { userId: User['id'] },
        start: string,
        end: string,
        interval: SharedType.TimeSeriesInterval
    ): Promise<AccountRollup[]>
}

export class AccountQueryService implements IAccountQueryService {
    constructor(private readonly logger: Logger, private readonly pg: PgService) {}

    async getHoldingsEnriched(accountId: Account['id'], { page, pageSize }: PaginationOptions) {
        const { rows } = await this.pg.pool.query<
            SharedType.HoldingEnriched & {
                cost_basis_user: Prisma.Decimal | null
                cost_basis_provider: Prisma.Decimal | null
            }
        >(
            sql`
              SELECT
                h.id,
                h.security_id,
                s.name,
                s.symbol,
                s.shares_per_contract,
                he.quantity,
                he.value,
                he.cost_basis,
                h.cost_basis_user,
                h.cost_basis_provider,
                he.cost_basis_per_share,
                he.price,
                he.price_prev,
                he.excluded
              FROM
                holdings_enriched he
                INNER JOIN security s ON s.id = he.security_id
                INNER JOIN holding h ON h.id = he.id
              WHERE
                he.account_id = ${accountId}
              ORDER BY
                he.excluded ASC,
                he.value DESC
              OFFSET ${page * pageSize}
              LIMIT ${pageSize};
          `
        )

        return rows
    }

    async getValuationTrends(accountId: Account['id'], start?: DateTime, end?: DateTime) {
        // start/end date SQL query params
        const pStart = start
            ? raw(`'${start.toISODate()}'`)
            : sql`account_value_start_date(${accountId}::int)`
        const pEnd = end ? raw(`'${end.toISODate()}'`) : sql`now()`

        const { rows } = await this.pg.pool.query<ValuationTrend>(
            sql`
              WITH valuation_trends AS (
                SELECT
                  date,
                  COALESCE(interpolated::numeric, filled) AS amount
                FROM (
                  SELECT
                    time_bucket_gapfill('1d', v.date) AS date,
                    interpolate(avg(v.amount)) AS interpolated,
                    locf(avg(v.amount)) AS filled
                  FROM
                    valuation v
                  WHERE
                    v.account_id = ${accountId}
                    AND v.date BETWEEN ${pStart} AND ${pEnd}
                  GROUP BY
                    1
                ) valuations_gapfilled
                WHERE
                  to_char(date, 'MM-DD') = '01-01'
              ), valuations_combined AS (
                SELECT
                  COALESCE(v.date, vt.date) AS date,
                  COALESCE(v.amount, vt.amount) AS amount,
                  v.id AS valuation_id
                FROM
                  (SELECT * FROM valuation WHERE account_id = ${accountId}) v
                  FULL OUTER JOIN valuation_trends vt ON vt.date = v.date
              )
              SELECT
                v.date,
                v.amount,
                v.valuation_id,
                v.amount - v.prev_amount AS period_change,
                ROUND((v.amount - v.prev_amount)::numeric / NULLIF(v.prev_amount, 0), 4) AS period_change_pct,
                v.amount - v.first_amount AS total_change,
                ROUND((v.amount - v.first_amount)::numeric / NULLIF(v.first_amount, 0), 4) AS total_change_pct
              FROM (
                SELECT
                  *,
                  LAG(amount, 1) OVER (ORDER BY date ASC) AS prev_amount,
                  (SELECT amount FROM valuations_combined ORDER BY date ASC LIMIT 1) AS first_amount
                FROM
                  valuations_combined
              ) v
              ORDER BY
                v.date ASC
          `
        )

        return rows
    }

    /**
     * Return formula is the "Basic Return with Cashflows at period end" outlined here - https://www.kitces.com/blog/twr-dwr-irr-calculations-performance-reporting-software-methodology-gips-compliance/
     */
    async getReturnSeries(accountId: Account['id'], start: string, end: string) {
        const pAccountIds = Array.isArray(accountId) ? accountId : [accountId]
        const pStart = raw(`'${start}'`)
        const pEnd = raw(`'${end}'`)

        const { rows } = await this.pg.pool.query<ReturnSeries>(
            sql`
              WITH start_date AS (
                SELECT
                  a.id AS "account_id",
                  GREATEST(account_value_start_date(a.id), a.start_date) AS "start_date"
                FROM
                  account a
                WHERE
                  a.id = ANY(${pAccountIds})
                GROUP BY
                  1
              ), external_flows AS (
                SELECT
                  it.account_id,
                  it.date,
                  SUM(it.amount) AS "amount"
                FROM
                  investment_transaction it
                  LEFT JOIN start_date sd ON sd.account_id = it.account_id
                WHERE
                  it.account_id = ANY(${pAccountIds})
                  AND it.date BETWEEN sd.start_date AND ${pEnd}
                  -- filter for investment_transactions that represent external flows
                  AND (
                    (it.plaid_type = 'cash' AND it.plaid_subtype IN ('contribution', 'deposit', 'withdrawal'))
                    OR (it.plaid_type = 'transfer' AND it.plaid_subtype IN ('transfer'))
                    OR (it.plaid_type = 'buy' AND it.plaid_subtype IN ('contribution'))
                    OR (it.finicity_transaction_id IS NOT NULL AND it.finicity_investment_transaction_type IN ('contribution', 'deposit', 'transfer'))
                  )
                GROUP BY
                  1, 2
              ), external_flow_totals AS (
                SELECT
                  account_id,
                  SUM(amount) as "amount"
                FROM
                  external_flows
                GROUP BY
                  1
              ), balances AS (
                SELECT
                  abg.account_id,
                  abg.date,
                  abg.balance,
                  0 - SUM(COALESCE(ef.amount, 0)) OVER (PARTITION BY abg.account_id ORDER BY abg.date ASC) AS "contributions_period",
                  COALESCE(-1 * (eft.amount - coalesce(SUM(ef.amount) OVER (PARTITION BY abg.account_id ORDER BY abg.date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0)), 0) AS "contributions"
                FROM
                  account_balances_gapfilled(
                    ${pStart},
                    ${pEnd},
                    '1d',
                    ${pAccountIds}
                  ) abg
                  LEFT JOIN external_flows ef ON ef.account_id = abg.account_id AND ef.date = abg.date
                  LEFT JOIN external_flow_totals eft ON eft.account_id = abg.account_id
              )
              SELECT
                b.account_id,
                b.date,
                b.balance,
                b.contributions,
                b.contributions_period,
                COALESCE(ROUND((b.balance - b0.balance - b.contributions_period) / COALESCE(NULLIF(b0.balance, 0), NULLIF(b.contributions_period, 0)), 4), 0) AS "rate_of_return"
              FROM
                balances b
                LEFT JOIN (
                  SELECT DISTINCT ON (account_id)
                    account_id,
                    balance
                  FROM
                    balances
                  ORDER BY
                    account_id, date ASC
                ) b0 ON b0.account_id = b.account_id
          `
        )

        return rows
    }

    async getBalanceSeries(
        accountId: Account['id'] | Account['id'][],
        start: string,
        end: string,
        interval: SharedType.TimeSeriesInterval
    ) {
        // by defining the query params upfront like this, we can easily copy-paste the query to debug in TablePlus w/ query param substitution
        const pAccountIds = Array.isArray(accountId) ? accountId : [accountId]
        const pStart = raw(`'${start}'`)
        const pEnd = raw(`'${end}'`)
        const pInterval = raw(`'${DbUtil.toPgInterval(interval)}'`)

        const { rows } = await this.pg.pool.query<BalanceSeries>(
            sql`
              SELECT
                abg.account_id,
                abg.date,
                abg.balance
              FROM
                account_balances_gapfilled(
                  ${pStart},
                  ${pEnd},
                  ${pInterval},
                  ${pAccountIds}
                ) abg
            `
        )

        return rows
    }

    /**
     * returns net worth time series for an account
     */
    async getNetWorthSeries(
        id: { userId: User['id'] } | { accountIds: Account['id'][] },
        start: string,
        end: string,
        interval: SharedType.TimeSeriesInterval
    ) {
        // by defining the query params upfront like this, we can easily copy-paste the query to debug in TablePlus w/ query param substitution
        const pAccountIds =
            'accountIds' in id
                ? id.accountIds
                : sql`(
                    SELECT
                      array_agg(a.id)
                    FROM
                      account a
                      LEFT JOIN account_connection ac ON ac.id = a.account_connection_id
                    WHERE
                      (a.user_id = ${id.userId} OR ac.user_id = ${id.userId})
                      AND a.is_active
                )`

        const pStart = raw(`'${start}'`)
        const pEnd = raw(`'${end}'`)
        const pInterval = raw(`'${DbUtil.toPgInterval(interval)}'`)

        const { rows } = await this.pg.pool.query<
            | {
                  date: string
                  classification: null
                  category: null
                  balance: Prisma.Decimal
              }
            | {
                  date: string
                  classification: AccountClassification
                  category: null
                  balance: Prisma.Decimal
              }
            | {
                  date: string
                  classification: AccountClassification
                  category: AccountCategory
                  balance: Prisma.Decimal
              }
        >(
            sql`
              SELECT
                abg.date,
                a.category,
                a.classification,
                SUM(CASE WHEN a.classification = 'asset' THEN abg.balance ELSE -abg.balance END) AS balance
              FROM
                account_balances_gapfilled(
                  ${pStart},
                  ${pEnd},
                  ${pInterval},
                  ${pAccountIds}
                ) abg
                INNER JOIN account a ON a.id = abg.account_id
              GROUP BY
                GROUPING SETS (
                  (abg.date, a.classification, a.category),
                  (abg.date, a.classification),
                  (abg.date)
                )
              ORDER BY date ASC;
          `
        )

        // Group independent rows into NetWorthSeries objects
        return _(rows)
            .groupBy((r) => r.date)
            .mapValues((data, date) => ({
                ...data.reduce(
                    (acc, d) => {
                        if (d.classification == null) {
                            return {
                                ...acc,
                                netWorth: d.balance,
                            }
                        }

                        if (d.category == null) {
                            return d.classification === 'asset'
                                ? { ...acc, assets: d.balance }
                                : { ...acc, liabilities: d.balance }
                        }

                        return {
                            ...acc,
                            categories: {
                                ...acc.categories,
                                [d.category]: d.balance,
                            },
                        }
                    },
                    {
                        date,
                        netWorth: new Prisma.Decimal(0),
                        assets: new Prisma.Decimal(0),
                        liabilities: new Prisma.Decimal(0),
                        categories: {},
                    }
                ),
            }))
            .values()
            .value()
    }

    async getRollup(
        id: { accountId: Account['id'] } | { userId: User['id'] },
        start: string,
        end: string,
        interval: SharedType.TimeSeriesInterval
    ) {
        // by defining the query params upfront like this, we can easily copy-paste the query to debug in TablePlus w/ query param substitution
        const pAccountIds =
            'accountId' in id
                ? [id.accountId]
                : sql`(
                    SELECT
                      array_agg(a.id)
                    FROM
                      account a
                      LEFT JOIN account_connection ac ON ac.id = a.account_connection_id
                    WHERE
                      (a.user_id = ${id.userId} OR ac.user_id = ${id.userId})
                      AND a.is_active
                )`

        const pStart = raw(`'${start}'`)
        const pEnd = raw(`'${end}'`)
        const pInterval = raw(`'${DbUtil.toPgInterval(interval)}'`)

        const { rows } = await this.pg.pool.query<AccountRollup>(
            sql`
              WITH account_rollup AS (
                SELECT
                  abg.date,
                  a.classification,
                  a.category,
                  a.id,
                  SUM(abg.balance) AS balance,
                  CASE GROUPING(abg.date, a.classification, a.category, a.id)
                    WHEN 3 THEN 'classification'
                    WHEN 1 THEN 'category'
                    WHEN 0 THEN 'account'
                    ELSE NULL
                  END AS grouping
                FROM
                  account_balances_gapfilled(
                    ${pStart},
                    ${pEnd},
                    ${pInterval},
                    ${pAccountIds}
                  ) abg
                  INNER JOIN account a ON a.id = abg.account_id
                GROUP BY
                  GROUPING SETS (
                    (abg.date, a.classification, a.category, a.id),
                    (abg.date, a.classification, a.category),
                    (abg.date, a.classification)
                  )
              )
              SELECT
                ar.date,
                ar.classification,
                ar.category,
                ar.id,
                ar.balance,
                ar.grouping,
                CASE
                  WHEN a.id IS NULL THEN NULL
                  ELSE json_build_object('id', a.id, 'name', a.name, 'mask', a.mask, 'syncStatus', a.sync_status, 'connection', CASE WHEN ac.id IS NULL THEN NULL ELSE json_build_object('name', ac.name, 'syncStatus', ac.sync_status) END)
                END AS account,
                ROUND(
                  CASE ar.grouping
                    WHEN 'account' THEN COALESCE(ar.balance / SUM(NULLIF(ar.balance, 0)) OVER (PARTITION BY ar.grouping, ar.date, ar.classification, ar.category), 0)
                    WHEN 'category' THEN COALESCE(ar.balance / SUM(NULLIF(ar.balance, 0)) OVER (PARTITION BY ar.grouping, ar.date, ar.classification), 0)
                    WHEN 'classification' THEN COALESCE(ar.balance / SUM(NULLIF(ar.balance, 0)) OVER (PARTITION BY ar.grouping, ar.date), 0)
                  END, 4) AS rollup_pct,
                ROUND(ar.balance / SUM(NULLIF(ar.balance, 0)) OVER (PARTITION BY ar.grouping, ar.date), 4) AS total_pct
              FROM
                account_rollup ar
                LEFT JOIN account a ON a.id = ar.id
                LEFT JOIN account_connection ac ON ac.id = a.account_connection_id
              ORDER BY
                ar.classification, ar.category, ar.id, ar.date;
          `
        )

        return rows
    }
}
