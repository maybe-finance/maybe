-- AlterTable
ALTER TABLE "investment_transaction"
  RENAME COLUMN "category" TO "category_old";

DROP VIEW IF EXISTS holdings_enriched;

ALTER TABLE "investment_transaction"
  ADD COLUMN "category" "InvestmentTransactionCategory" NOT NULL DEFAULT 'other'::"InvestmentTransactionCategory";

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
        it.category = 'buy'
        AND it.quantity > 0
      GROUP BY
        it.account_id,
        it.security_id
    ) tcb ON tcb.account_id = h.account_id AND tcb.security_id = s.id
);

CREATE OR REPLACE FUNCTION calculate_return_dietz(p_account_id account.id%type, p_start date, p_end date, out percentage numeric, out amount numeric) AS $$
  DECLARE
    v_start date := GREATEST(p_start, (SELECT MIN(date) FROM account_balance WHERE account_id = p_account_id));
    v_end date := p_end;
    v_days int := v_end - v_start;
  BEGIN
    SELECT
      ROUND((b1.balance - b0.balance - flows.net) / NULLIF(b0.balance + flows.weighted, 0), 4) AS "percentage",
      b1.balance - b0.balance - flows.net AS "amount"
    INTO
      percentage, amount
  FROM
    account a
    LEFT JOIN LATERAL (
      SELECT
        COALESCE(SUM(-fw.flow), 0) AS "net",
        COALESCE(SUM(-fw.flow * fw.weight), 0) AS "weighted"
      FROM (
        SELECT
          SUM(it.amount) AS flow,
          (v_days - (it.date - v_start))::numeric / v_days AS weight
        FROM
          investment_transaction it
        WHERE
          it.account_id = a.id
          AND it.date BETWEEN v_start AND v_end
          -- filter for investment_transactions that represent external flows
          AND it.category = 'transfer'
        GROUP BY
          it.date
      ) fw
    ) flows ON TRUE
    LEFT JOIN LATERAL (
      SELECT
        ab.balance AS "balance"
      FROM
        account_balance ab
      WHERE
        ab.account_id = a.id AND ab.date <= v_start
      ORDER BY
        ab.date DESC
      LIMIT 1
    ) b0 ON TRUE
    LEFT JOIN LATERAL (
      SELECT
        COALESCE(ab.balance, a.current_balance) AS "balance"
      FROM
        account_balance ab
      WHERE
        ab.account_id = a.id AND ab.date <= v_end
      ORDER BY
        ab.date DESC
      LIMIT 1
    ) b1 ON TRUE
  WHERE
    a.id = p_account_id;
  END;
$$ LANGUAGE plpgsql STABLE;

ALTER TABLE "investment_transaction"
  DROP COLUMN "category_old";
