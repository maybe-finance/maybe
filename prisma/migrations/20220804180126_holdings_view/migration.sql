-- update cost basis columns
ALTER TABLE "holding" RENAME COLUMN "cost_basis" TO "cost_basis_provider";
ALTER TABLE "holding" ADD COLUMN "cost_basis_user" DECIMAL(23,8);
ALTER TABLE "holding" ADD COLUMN "cost_basis" DECIMAL(23,8) GENERATED ALWAYS AS (
  COALESCE(cost_basis_user, cost_basis_provider)
) STORED;

-- create holdings view
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
    pricing_prev.price_close AS "price_prev"
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
        (it.plaid_type = 'buy' OR it.finicity_investment_transaction_type = 'purchased')
        AND it.quantity > 0
      GROUP BY
        it.account_id,
        it.security_id
    ) tcb ON tcb.account_id = h.account_id AND tcb.security_id = s.id
);