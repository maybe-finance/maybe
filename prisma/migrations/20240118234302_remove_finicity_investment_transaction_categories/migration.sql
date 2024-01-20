-- AlterTable
ALTER TABLE "investment_transaction"
    RENAME COLUMN "category" TO "category_old";

DROP VIEW IF EXISTS holdings_enriched;

ALTER TABLE "investment_transaction"
ADD COLUMN "category" "InvestmentTransactionCategory" NOT NULL GENERATED ALWAYS AS (
  CASE
    WHEN "plaid_type" = 'buy' THEN 'buy'::"InvestmentTransactionCategory"
    WHEN "plaid_type" = 'sell' THEN 'sell'::"InvestmentTransactionCategory"
    WHEN "plaid_subtype" IN ('dividend', 'qualified dividend', 'non-qualified dividend') THEN 'dividend'::"InvestmentTransactionCategory"
    WHEN "plaid_subtype" IN ('non-resident tax', 'tax', 'tax withheld') THEN 'tax'::"InvestmentTransactionCategory"
    WHEN "plaid_type" = 'fee' OR "plaid_subtype" IN ('account fee', 'legal fee', 'management fee', 'margin expense', 'transfer fee', 'trust fee') THEN 'fee'::"InvestmentTransactionCategory"
    WHEN "plaid_type" = 'cash' THEN 'transfer'::"InvestmentTransactionCategory"
    WHEN "plaid_type" = 'cancel' THEN 'cancel'::"InvestmentTransactionCategory"

    ELSE 'other'::"InvestmentTransactionCategory"
  END
) STORED;

CREATE OR REPLACE VIEW holdings_enriched AS (
  SELECT
    h.id,
    h.account_id,
    h.security_id,
    h.quantity,
    COALESCE(pricing_latest.price_close * h.quantity * COALESCE(s.shares_per_contract, 1), h.value) AS "value",
    COALESCE(h.cost_basis, tcb.cost_basis * h.quantity) AS "cost_basis",
    COALESCE(h.cost_basis / h.quantity / COALESCE(s.shares_per_contract, 1), tcb.cost_basis) AS "cost_basis_per_share",
    pricing_latest.price_close AS "price",
    pricing_prev.price_close AS "price_prev",
    h.excluded
  FROM
    holding h
    INNER JOIN security s ON s.id = h.security_id
    -- latest security pricing
    LEFT JOIN LATERAL (
      SELECT
        price_close
      FROM
        security_pricing
      WHERE
        security_id = h.security_id
      ORDER BY
        date DESC
      LIMIT 1
    ) pricing_latest ON true
    -- previous security pricing (for computing daily ∆)
    LEFT JOIN LATERAL (
      SELECT
        price_close
      FROM
        security_pricing
      WHERE
        security_id = h.security_id
      ORDER BY
        date DESC
      LIMIT 1
      OFFSET 1
    ) pricing_prev ON true
    -- calculate cost basis from transactions
    LEFT JOIN (
      SELECT
        it.account_id,
        it.security_id,
        SUM(it.quantity * it.price) / SUM(it.quantity) AS cost_basis
      FROM
        investment_transaction it
      WHERE
        it.plaid_type = 'buy'
        AND it.quantity > 0
      GROUP BY
        it.account_id,
        it.security_id
    ) tcb ON tcb.account_id = h.account_id AND tcb.security_id = s.id
);

ALTER TABLE "investment_transaction" DROP COLUMN "category_old";
