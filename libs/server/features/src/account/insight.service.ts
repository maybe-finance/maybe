import type { Logger } from 'winston'
import type {
    Security,
    Account,
    Holding,
    PrismaClient,
    User,
    TransactionType,
} from '@prisma/client'
import { Prisma } from '@prisma/client'
import _ from 'lodash'
import { SharedUtil, type SharedType } from '@maybe-finance/shared'
import { DbUtil } from '@maybe-finance/server/shared'
import { DateTime } from 'luxon'

type UserInsightOptions = {
    userId: User['id']
    accountIds?: Account['id'] | Account['id'][]
    now?: DateTime
}

type AccountInsightOptions = {
    accountId: Account['id']
    now?: DateTime
}

type HoldingInsightOptions = {
    holding: Holding
    now?: DateTime
}

type PlanInsightOptions = {
    userId: User['id']
    now?: DateTime
}

export interface IInsightService {
    getUserInsights(options: UserInsightOptions): Promise<SharedType.UserInsights>
    getAccountInsights(options: AccountInsightOptions): Promise<SharedType.AccountInsights>
    getHoldingInsights(options: HoldingInsightOptions): Promise<SharedType.HoldingInsights>
    getPlanInsights(options: PlanInsightOptions): Promise<SharedType.PlanInsights>
}

export class InsightService implements IInsightService {
    constructor(private readonly logger: Logger, private readonly prisma: PrismaClient) {}

    async getUserInsights({
        userId,
        accountIds,
        now = DateTime.utc(),
    }: UserInsightOptions): Promise<SharedType.UserInsights> {
        const pAccountIds =
            accountIds != null
                ? Array.isArray(accountIds)
                    ? accountIds
                    : [accountIds]
                : Prisma.sql`(
                    SELECT
                      a.id
                    FROM
                      account a
                      LEFT JOIN account_connection ac ON ac.id = a.account_connection_id
                    WHERE
                      (a.user_id = ${userId} OR ac.user_id = ${userId})
                      AND a.is_active
                  )`

        const [user, accountSummary, holdingBreakdown, assetSummary, transactionSummary] =
            await this.prisma.$transaction([
                this.prisma.user.findUniqueOrThrow({ where: { id: userId } }),
                this._accountSummary(pAccountIds, now),
                this._holdingBreakdown(pAccountIds),
                this._assetSummary(pAccountIds, now),
                this._transactionSummary(pAccountIds, now),
            ])

        const assets = accountSummary.find(
            (row) => row.grouping === 'classification' && row.classification === 'asset'
        ) ?? {
            balance_now: new Prisma.Decimal(0),
            balance_yearly: new Prisma.Decimal(0),
            balance_monthly: new Prisma.Decimal(0),
            balance_weekly: new Prisma.Decimal(0),
        }
        const assetBuckets = assetSummary.filter(
            (row): row is Extract<typeof row, { classification: 'asset' }> =>
                row.classification === 'asset'
        )

        const liabilities = accountSummary.find(
            (row) => row.grouping === 'classification' && row.classification === 'liability'
        ) ?? {
            balance_now: new Prisma.Decimal(0),
            balance_yearly: new Prisma.Decimal(0),
            balance_monthly: new Prisma.Decimal(0),
            balance_weekly: new Prisma.Decimal(0),
        }
        const liabilityBuckets = assetSummary.filter(
            (row): row is Extract<typeof row, { classification: 'liability' }> =>
                row.classification === 'liability'
        )

        const netWorthNow = assets.balance_now.minus(liabilities.balance_now)
        const netWorthYearly = assets.balance_yearly.minus(liabilities.balance_yearly)
        const netWorthMonthly = assets.balance_monthly.minus(liabilities.balance_monthly)
        const netWorthWeekly = assets.balance_weekly.minus(liabilities.balance_weekly)

        const liquidAssetsNow = new Prisma.Decimal(
            assetBuckets.find((row) => row.bucket === 'assets-liquid')?.balance_now ?? 0
        )

        const incomeMonthlyCalculated = new Prisma.Decimal(
            transactionSummary.find((row) => row.type === 'INCOME')?.avg_6mo ?? 0
        )
        const incomeMonthly = user.monthlyIncomeUser ?? incomeMonthlyCalculated

        const expensesMonthlyCalculated = new Prisma.Decimal(
            transactionSummary.find((row) => row.type === 'EXPENSE')?.avg_6mo ?? 0
        )
        const expensesMonthly = user.monthlyExpensesUser ?? expensesMonthlyCalculated

        const debtMonthlyCalculated = new Prisma.Decimal(
            transactionSummary.find((row) => row.type === 'PAYMENT')?.avg_6mo ?? 0
        )
        const debtMonthly = user.monthlyDebtUser ?? debtMonthlyCalculated

        const toAmountAndPct = (
            value: Prisma.Decimal | null | undefined,
            total: Prisma.Decimal
        ) => {
            const amount = value ?? new Prisma.Decimal(0)
            return { amount, percentage: amount.dividedBy(total) }
        }

        return {
            netWorthToday: netWorthNow,
            netWorth: {
                yearly: DbUtil.calculateTrend(netWorthYearly, netWorthNow),
                monthly: DbUtil.calculateTrend(netWorthMonthly, netWorthNow),
                weekly: DbUtil.calculateTrend(netWorthWeekly, netWorthNow),
            },
            safetyNet: {
                months: liquidAssetsNow.dividedBy(expensesMonthly).clampedTo(0, Infinity),
                spending: expensesMonthly,
            },
            debtIncome: {
                ratio: debtMonthly.dividedBy(incomeMonthly),
                debt: debtMonthly,
                income: incomeMonthly,
                user: {
                    debt: user.monthlyDebtUser,
                    income: user.monthlyIncomeUser,
                },
                calculated: {
                    debt: debtMonthlyCalculated,
                    income: incomeMonthlyCalculated,
                },
            },
            debtAsset: {
                ratio: liabilities.balance_now.dividedBy(assets.balance_now),
                debt: liabilities.balance_now,
                asset: assets.balance_now,
            },
            assetSummary: {
                liquid: toAmountAndPct(liquidAssetsNow, assets.balance_now),
                illiquid: toAmountAndPct(
                    assetBuckets.find((row) => row.bucket === 'assets-illiquid')?.balance_now,
                    assets.balance_now
                ),
                yielding: toAmountAndPct(
                    assetBuckets.find((row) => row.bucket === 'assets-yielding')?.balance_now,
                    assets.balance_now
                ),
            },
            debtSummary: {
                good: toAmountAndPct(
                    liabilityBuckets.find((row) => row.bucket === 'debt-good')?.balance_now,
                    liabilities.balance_now
                ),
                bad: toAmountAndPct(
                    liabilityBuckets.find((row) => row.bucket === 'debt-bad')?.balance_now,
                    liabilities.balance_now
                ),
                total: toAmountAndPct(
                    liabilities.balance_now,
                    assets.balance_now.plus(liabilities.balance_now)
                ),
            },
            transactionSummary: {
                income: incomeMonthly,
                expenses: expensesMonthly,
                payments: debtMonthly,
            },
            transactionBreakdown: transactionSummary.map((row) => ({
                category: row.type,
                amount: row.amount,
                avg_6mo: row.avg_6mo,
            })),
            accountSummary: accountSummary
                .filter(
                    (row): row is Extract<typeof row, { grouping: 'category' }> =>
                        row.grouping === 'category'
                )
                .map((row) => ({
                    classification: row.classification,
                    category: row.category,
                    balance: row.balance_now,
                    allocation: row.allocation_now,
                })),
            holdingBreakdown: _(holdingBreakdown)
                .filter((h) => h.grouping === 'category')
                .map((c) => ({
                    ...c,
                    holdings: _(holdingBreakdown)
                        .filter(
                            (h): h is Extract<typeof h, { grouping: 'security' }> =>
                                h.grouping === 'security' && h.category === c.category
                        )
                        .orderBy((h) => +h.value, 'desc')
                        .value(),
                }))
                .orderBy((h) => +h.value, 'desc')
                .value(),
        }
    }

    async getAccountInsights({
        accountId,
        now = DateTime.utc(),
    }: AccountInsightOptions): Promise<SharedType.AccountInsights> {
        const [
            holdingSummary,
            [returns],
            [contributions],
            {
                _sum: { fees },
            },
        ] = await Promise.all([
            this._holdingSummary(accountId),
            this._portfolioReturn(accountId, now),
            this._investmentTransactionSummary(accountId, now),
            this.prisma.investmentTransaction.aggregate({
                where: { accountId },
                _sum: {
                    fees: true,
                },
            }),
        ])

        const { value, cost_basis, pnl_amt, pnl_pct } = holdingSummary.find(
            (s): s is Extract<typeof s, { asset_class: null }> => SharedUtil.isNull(s.asset_class)
        )!

        return {
            portfolio:
                value != null
                    ? {
                          return: {
                              '1m': DbUtil.toTrend(returns.amt_1m, returns.pct_1m),
                              '1y': DbUtil.toTrend(returns.amt_1y, returns.pct_1y),
                              ytd: DbUtil.toTrend(returns.amt_ytd, returns.pct_ytd),
                          },
                          pnl: DbUtil.toTrend(pnl_amt, pnl_pct),
                          costBasis: DbUtil.toDecimal(cost_basis),
                          contributions: {
                              ytd: {
                                  amount: DbUtil.toDecimal(contributions.ytd_total).negated(),
                                  monthlyAvg: DbUtil.toDecimal(contributions.ytd_total)
                                      .dividedBy(DateTime.utc().month)
                                      .negated(),
                              },
                              lastYear: {
                                  amount: DbUtil.toDecimal(contributions.last_year_total).negated(),
                                  monthlyAvg: DbUtil.toDecimal(contributions.last_year_total)
                                      .dividedBy(12)
                                      .negated(),
                              },
                          },
                          fees: fees ?? new Prisma.Decimal(0),
                          holdingBreakdown: holdingSummary
                              .filter(
                                  (s): s is Extract<typeof s, { asset_class: string }> =>
                                      !SharedUtil.isNull(s.asset_class)
                              )
                              .map((s) => ({
                                  asset_class: s.asset_class,
                                  amount: DbUtil.toDecimal(s.value),
                                  percentage: DbUtil.toDecimal(s.percentage),
                              })),
                      }
                    : undefined,
        }
    }

    async getHoldingInsights({
        holding,
    }: HoldingInsightOptions): Promise<SharedType.HoldingInsights> {
        const [
            {
                _sum: { amount: dividends },
            },
            [{ allocation }],
        ] = await Promise.all([
            this.prisma.investmentTransaction.aggregate({
                _sum: {
                    amount: true,
                },
                where: {
                    security: { id: holding.securityId },
                    accountId: holding.accountId,
                    OR: [
                        {
                            plaidSubtype: 'dividend',
                        },
                        { category: 'dividend' },
                    ],
                },
            }),
            this.prisma.$queryRaw<[{ allocation: Prisma.Decimal | null }]>`
              WITH security_allocations as (
                SELECT
                  security_id,
                  value / SUM(value) OVER () as "allocation"
                FROM
                  holdings_enriched
                WHERE
                  account_id = ${holding.accountId}
              )
              SELECT allocation
              FROM security_allocations
              WHERE security_id = ${holding.securityId}
            `,
        ])

        return {
            holding,
            dividends: DbUtil.toDecimal(dividends),
            allocation: DbUtil.toDecimal(allocation),
        }
    }

    async getPlanInsights({ userId, now = DateTime.utc() }: PlanInsightOptions) {
        const accountIds = Prisma.sql`(
          SELECT
            a.id
          FROM
            account a
            LEFT JOIN account_connection ac ON ac.id = a.account_connection_id
          WHERE
            (a.user_id = ${userId} OR ac.user_id = ${userId})
            AND a.is_active
        )`

        const [user, projectionAssetBreakdown, projectionLiabilityBreakdown, transactionSummary] =
            await Promise.all([
                this.prisma.user.findUniqueOrThrow({ where: { id: userId } }),
                this._projectionAssetBreakdown(accountIds, now),
                this._projectionLiabilityBreakdown(accountIds, now),
                this._transactionSummary(accountIds, now),
            ])

        const incomeMonthly =
            user.monthlyIncomeUser ??
            new Prisma.Decimal(
                transactionSummary.find((row) => row.type === 'INCOME')?.avg_6mo ?? 0
            )

        const expensesMonthly =
            user.monthlyExpensesUser ??
            new Prisma.Decimal(
                transactionSummary.find((row) => row.type === 'EXPENSE')?.amount ?? 0
            )

        return {
            projectionAssetBreakdown,
            projectionLiabilityBreakdown,
            income: incomeMonthly.times(12),
            expenses: expensesMonthly.times(12),
        }
    }

    private _accountSummary(accountIds: Prisma.Sql | number[], now: DateTime) {
        const timepoints = {
            now,
            yearly: now.minus({ years: 1 }),
            monthly: now.minus({ months: 1 }),
            weekly: now.minus({ weeks: 1 }),
        }

        // discriminated union represents valid columns for each grouping
        type AccountGrouping =
            | {
                  grouping: 'classification'
                  classification: Account['classification']
              }
            | {
                  grouping: 'category'
                  classification: Account['classification']
                  category: Account['category']
              }

        return this.prisma.$queryRaw<
            (AccountGrouping & {
                [key in keyof typeof timepoints as `balance_${key}`]: Prisma.Decimal
            } & {
                [key in keyof typeof timepoints as `allocation_${key}`]: Prisma.Decimal
            })[]
        >`
          WITH category_rollup AS (
            SELECT
              CASE GROUPING(a.classification, a.category)
                WHEN 0 THEN 'category'
                WHEN 1 THEN 'classification'
              END AS grouping,
              a.classification,
              a.category,
              ${Prisma.join(
                  Object.entries(timepoints).map(([key, date]) => {
                      const pCol = Prisma.raw(`"balance_${key}"`)
                      const pDate = Prisma.raw(`'${date.toISODate()}'`)
                      return Prisma.sql`
                        SUM(
                          CASE
                            WHEN a.start_date IS NOT NULL AND ${pDate} < a.start_date THEN 0
                            ELSE COALESCE(
                              (SELECT balance FROM account_balance WHERE account_id = a.id AND date <= ${pDate} ORDER BY date DESC LIMIT 1),
                              (SELECT balance FROM account_balance WHERE account_id = a.id AND date > ${pDate} ORDER BY date ASC LIMIT 1),
                              a.current_balance,
                              0
                            )
                          END
                        ) AS ${pCol}
                      `
                  })
              )}
            FROM
              account a
            WHERE
              a.id IN ${accountIds}
            GROUP BY
              GROUPING SETS (
                (a.classification, a.category),
                (a.classification)
              )
          )
          SELECT
            *,
            ${Prisma.join(
                Object.entries(timepoints).map(([key]) => {
                    const pBalanceCol = Prisma.raw(`"balance_${key}"`)
                    const pAllocationCol = Prisma.raw(`"allocation_${key}"`)
                    return Prisma.sql`
                      CASE grouping
                        WHEN 'category' THEN COALESCE(${pBalanceCol} / SUM(NULLIF(${pBalanceCol}, 0)) OVER (PARTITION BY grouping, classification), 0)
                        WHEN 'classification' THEN COALESCE(${pBalanceCol} / SUM(NULLIF(${pBalanceCol}, 0)) OVER (PARTITION BY grouping), 0)
                      END AS ${pAllocationCol}
                    `
                })
            )}
          FROM
            category_rollup
        `
    }

    private _assetSummary(accountIds: Prisma.Sql | number[], now: DateTime) {
        const timepoints = {
            now,
            yearly: now.minus({ years: 1 }),
            monthly: now.minus({ months: 1 }),
            weekly: now.minus({ weeks: 1 }),
        }

        // discriminated union represents valid columns for each grouping
        type AssetGrouping =
            | {
                  classification: 'asset'
                  bucket: 'assets-liquid' | 'assets-illiquid' | 'assets-yielding' | 'assets-other'
              }
            | {
                  classification: 'liability'
                  bucket: 'debt-good' | 'debt-bad' | 'debt-other'
              }

        return this.prisma.$queryRaw<
            (AssetGrouping & {
                [key in keyof typeof timepoints as `balance_${key}`]: Prisma.Decimal
            })[]
        >`
        SELECT
          a.classification,
          x.bucket,
          ${Prisma.join(
              Object.entries(timepoints).map(([key, date]) => {
                  const pCol = Prisma.raw(`"balance_${key}"`)
                  const pDate = Prisma.raw(`'${date.toISODate()}'`)
                  return Prisma.sql`
                    SUM(
                      CASE
                        WHEN a.start_date IS NOT NULL AND ${pDate} < a.start_date THEN 0
                        ELSE COALESCE(
                          (SELECT balance FROM account_balance WHERE account_id = a.id AND date <= ${pDate} ORDER BY date DESC LIMIT 1),
                          (SELECT balance FROM account_balance WHERE account_id = a.id AND date > ${pDate} ORDER BY date ASC LIMIT 1),
                          a.current_balance,
                          0
                        )
                      END
                    ) AS ${pCol}
                  `
              })
          )}
        FROM
          account a
          LEFT JOIN LATERAL (
            SELECT
              UNNEST(
                CASE a.classification
                  WHEN 'asset' THEN (
                    CASE
                      WHEN a.category = 'cash' THEN ARRAY['assets-liquid']
                      WHEN a.category = 'property' THEN ARRAY['assets-illiquid', 'assets-yielding']
                      WHEN a.category = 'investment' THEN ARRAY['assets-illiquid', 'assets-yielding']
                      ELSE ARRAY['assets-other']
                    END
                  )
                  WHEN 'liability' THEN (
                    CASE
                      WHEN a.category = 'loan' AND a.subcategory
                        IN ('business', 'commercial', 'construction', 'mortgage')
                        THEN ARRAY['debt-good']
                      WHEN a.category = 'loan' AND a.subcategory
                        IN ('consumer', 'home equity', 'overdraft', 'line of credit')
                        THEN ARRAY['debt-bad']
                      ELSE ARRAY['debt-other']
                    END
                  )
                END
              ) AS bucket
          ) x ON true
        WHERE
          a.id IN ${accountIds}
        GROUP BY
          a.classification, x.bucket
      `
    }

    private _transactionSummary(accountIds: Prisma.Sql | number[], now: DateTime) {
        const pNow = now.toISODate()

        return this.prisma.$queryRaw<
            {
                type: TransactionType
                amount: Prisma.Decimal
                avg_6mo: Prisma.Decimal
            }[]
        >`
          WITH txns AS (
            SELECT
              t.id,
              t.date,
              t.amount,
              t.flow,
              t.type,
              t."accountType"
            FROM
              transactions_enriched t
            WHERE
              t."accountId" IN ${accountIds}
              AND NOT t.excluded
              AND t.date >= date_trunc('month', ${pNow}::date - interval '6 months')
              AND t.date < date_trunc('month', ${pNow}::date)
          ), txn_type_months AS (
            SELECT DISTINCT
              t.type,
              date_trunc('month', d.date) AS "month"
            FROM
              unnest(enum_range(NULL::"TransactionType")) t(type)
              CROSS JOIN generate_series(date_trunc('month', (SELECT MIN(date) FROM txns)), now(), '1 month') d(date)
          ), txn_monthly_agg AS (
            SELECT
              t.type,
              date_trunc('month', t.date) AS "month",
              ABS(SUM(t.amount)) AS amount
            FROM
              txns t
            WHERE
              -- filter out credit account payments until we have a way to distinguish interest vs balance payments
              NOT (t.type = 'PAYMENT' AND t."accountType" = 'CREDIT')
            GROUP BY
              1, 2
          ), monthly_summary AS (
            SELECT
              ttm.type,
              ttm.month,
              COALESCE(tma.amount, 0) AS amount,
              AVG(COALESCE(tma.amount, 0)) OVER (PARTITION BY ttm.type ORDER BY ttm.month ASC ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS "avg_6mo"
            FROM
              txn_type_months ttm
              LEFT JOIN txn_monthly_agg tma ON tma.type IS NOT DISTINCT FROM ttm.type AND tma.month = ttm.month
          )
          SELECT
            type,
            amount,
            avg_6mo
          FROM
            monthly_summary
          WHERE
            month = date_trunc('month', ${pNow}::date - interval '1 month');
        `
    }

    private _holdingSummary(accountId: Account['id']) {
        return this.prisma.$queryRaw<
            (
                | {
                      asset_class: string
                      value: Prisma.Decimal
                      percentage: Prisma.Decimal
                      cost_basis: Prisma.Decimal | null
                      pnl_amt: Prisma.Decimal | null
                      pnl_pct: Prisma.Decimal | null
                  }
                | {
                      asset_class: null
                      value: Prisma.Decimal | null
                      percentage: Prisma.Decimal | null
                      cost_basis: Prisma.Decimal | null
                      pnl_amt: Prisma.Decimal | null
                      pnl_pct: Prisma.Decimal | null
                  }
            )[]
        >`
          SELECT
            s.asset_class,
            SUM(h.value) AS "value",
            ROUND(SUM(h.value) / SUM(SUM(h.value)) OVER (PARTITION BY GROUPING(s.asset_class)), 4) AS "percentage",
            SUM(h.cost_basis) AS "cost_basis",
            SUM(h.value - h.cost_basis) AS "pnl_amt",
            ROUND(SUM(h.value - h.cost_basis) / NULLIF(SUM(h.cost_basis), 0), 4) AS "pnl_pct"
          FROM
            holdings_enriched h
            INNER JOIN (
              SELECT
                id,
                asset_class
              FROM
                "security"
            ) s ON s.id = h.security_id
          WHERE
            h.account_id = ${accountId}
          GROUP BY
            ROLLUP (s.asset_class)
        `
    }

    private _holdingBreakdown(accountIds: Prisma.Sql | number[]) {
        type HoldingCategory = 'stocks' | 'fixed_income' | 'cash' | 'crypto' | 'other'

        type HoldingBreakdown =
            | {
                  grouping: 'category'
                  category: HoldingCategory
                  security: null
                  value: Holding['value']
                  allocation: Prisma.Decimal
              }
            | {
                  grouping: 'security'
                  category: HoldingCategory
                  security: Pick<Security, 'id' | 'symbol' | 'name'>
                  value: Holding['value']
                  allocation: Prisma.Decimal
              }

        return this.prisma.$queryRaw<HoldingBreakdown[]>`
          WITH holding_rollup AS (
            SELECT
              CASE GROUPING(x.category, h.security_id)
                WHEN 0 THEN 'security'
                WHEN 1 THEN 'category'
              END AS "grouping",
              x.category,
              h.security_id,
              SUM(h.value) AS "value",
              SUM(h.value) / NULLIF(SUM(SUM(h.value)) OVER (PARTITION BY GROUPING(x.category, h.security_id)), 0) AS "allocation"
            FROM
              holdings_enriched h
              INNER JOIN security s ON s.id = h.security_id
              LEFT JOIN LATERAL (
                SELECT
                  s.asset_class AS "category"
              ) x ON TRUE
            WHERE
              h.account_id IN ${accountIds}
            GROUP BY
              x.category, ROLLUP (h.security_id)
          )
          SELECT
            r.grouping,
            r.category,
            CASE r.grouping WHEN 'security' THEN json_build_object('id', s.id, 'symbol', s.symbol, 'name', s.name) ELSE NULL END AS "security",
            r.value,
            r.allocation
          FROM
            holding_rollup r
            LEFT JOIN security s ON s.id = r.security_id
        `
    }

    private _investmentTransactionSummary(accountId: Account['id'], now: DateTime) {
        return this.prisma.$queryRaw<
            [
                {
                    last_year_total: Prisma.Decimal
                    ytd_total: Prisma.Decimal
                }
            ]
        >`
          WITH cashflow_txns AS (
            SELECT
              (date_trunc('month', it.date) + interval '1 month' - interval '1 day')::date AS "month",
              SUM(it.amount) as "amount"
            FROM
              investment_transaction it
              LEFT JOIN account a ON a.id = it.account_id
            WHERE
              it.account_id = ${accountId}
              AND it.category = 'transfer'
              -- Exclude any contributions made prior to the start date since balances will be 0
              AND (a.start_date is NULL OR it.date >= a.start_date)
            GROUP BY 1
          )
          SELECT
            COALESCE(sum(amount) FILTER (WHERE month >= date_trunc('year', now())), 0) AS ytd_total,
            COALESCE(sum(amount) FILTER (WHERE month BETWEEN (date_trunc('year', now()) - interval '1 year') AND date_trunc('year', now())), 0) AS last_year_total
          FROM
            cashflow_txns
        `
    }

    private _portfolioReturn(accountId: Account['id'], now: DateTime) {
        const timepoints = {
            '1m': [now.minus({ months: 1 }), now],
            '1y': [now.minus({ years: 1 }), now],
            ytd: [now.startOf('year'), now],
        }

        return this.prisma.$queryRaw<
            [
                {
                    [key in keyof typeof timepoints as `pct_${key}`]: Prisma.Decimal
                } & {
                    [key in keyof typeof timepoints as `amt_${key}`]: Prisma.Decimal
                }
            ]
        >`
          SELECT
            *
          FROM
            ${Prisma.join(
                Object.entries(timepoints).map(([key, [start, end]]) => {
                    const pAccountId = Prisma.raw(accountId.toString())
                    const pStart = Prisma.raw(`'${start.toISODate()}'`)
                    const pEnd = Prisma.raw(`'${end.toISODate()}'`)
                    const pKey = Prisma.raw(key)
                    return Prisma.sql`
                      calculate_return_dietz(${pAccountId}, ${pStart}, ${pEnd}) ror_${pKey}(pct_${pKey}, amt_${pKey})
                    `
                })
            )}
        `
    }

    private _projectionAssetBreakdown(accountIds: Prisma.Sql, now: DateTime) {
        const pAccountIds = accountIds
        const pNow = now.toISODate()

        return this.prisma.$queryRaw<
            { type: SharedType.ProjectionAssetType; amount: Prisma.Decimal }[]
        >`
          SELECT
            asset_type AS "type",
            SUM(amount) AS "amount"
          FROM (
            -- non-investment accounts / investment accounts with 0 holdings
            SELECT
              x.asset_type,
              SUM(
                CASE
                  WHEN a.start_date IS NOT NULL AND ${pNow}::date < a.start_date THEN 0
                  ELSE COALESCE(
                    (SELECT balance FROM account_balance WHERE account_id = a.id AND date <= ${pNow}::date ORDER BY date DESC LIMIT 1),
                    (SELECT balance FROM account_balance WHERE account_id = a.id AND date > ${pNow}::date ORDER BY date ASC LIMIT 1),
                    a.current_balance,
                    0
                  )
                END
              ) AS "amount"
            FROM
              account a
              LEFT JOIN LATERAL (
                SELECT
                  CASE
                    WHEN a.type IN ('DEPOSITORY', 'INVESTMENT') THEN 'cash'
                    WHEN a.type IN ('PROPERTY') THEN 'property'
                    ELSE 'other'
                  END AS "asset_type"
              ) x ON true
            WHERE
              a.id IN ${pAccountIds}
              AND a.classification = 'asset'
              AND (a.type <> 'INVESTMENT' OR NOT EXISTS (SELECT 1 FROM holding h WHERE h.account_id = a.id))
            GROUP BY
              x.asset_type
            UNION ALL
            -- investment accounts
            SELECT
              s.asset_class AS "asset_type",
              SUM(h.value) AS "amount"
            FROM
              holdings_enriched h
              INNER JOIN (
                SELECT
                  id,
                  asset_class
                FROM
                  "security"
              ) s ON s.id = h.security_id
            WHERE
              h.account_id IN ${pAccountIds}
            GROUP BY
              s.asset_class
          ) x
          GROUP BY
            1
        `
    }

    private _projectionLiabilityBreakdown(accountIds: Prisma.Sql, now: DateTime) {
        const pAccountIds = accountIds
        const pNow = now.toISODate()

        return this.prisma.$queryRaw<
            { type: SharedType.ProjectionLiabilityType; amount: Prisma.Decimal }[]
        >`
          SELECT
            x.asset_type AS "type",
            SUM(
              CASE
                WHEN a.start_date IS NOT NULL AND ${pNow}::date < a.start_date THEN 0
                ELSE COALESCE(
                  (SELECT balance FROM account_balance WHERE account_id = a.id AND date <= ${pNow}::date ORDER BY date DESC LIMIT 1),
                  (SELECT balance FROM account_balance WHERE account_id = a.id AND date > ${pNow}::date ORDER BY date ASC LIMIT 1),
                  a.current_balance,
                  0
                )
              END
            ) AS "amount"
          FROM
            account a
            LEFT JOIN LATERAL (
              SELECT
                CASE
                  WHEN a.type IN ('CREDIT') THEN 'credit'
                  WHEN a.type IN ('LOAN') THEN 'loan'
                  ELSE 'other'
                END AS "asset_type"
            ) x ON true
          WHERE
            a.id IN ${pAccountIds}
            AND a.classification = 'liability'
          GROUP BY
            x.asset_type
        `
    }
}
