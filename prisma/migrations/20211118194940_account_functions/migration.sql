-- determines the bookkeeping type of an account
CREATE OR REPLACE FUNCTION account_value_type(p_account_id int) RETURNS text AS $$
  SELECT
    CASE
      WHEN EXISTS (SELECT 1 FROM investment_transaction WHERE account_id = p_account_id) THEN 'investment_transaction'
      WHEN EXISTS (SELECT 1 FROM valuation WHERE account_id = p_account_id) THEN 'valuation'
      ELSE 'transaction'
    END
$$ LANGUAGE SQL STABLE;


-- returns the start date of the account from a bookkeeping perspective
CREATE OR REPLACE FUNCTION account_value_start_date(p_account_id int) RETURNS date AS $$
  SELECT
    CASE
      WHEN account_value_type(p_account_id) = 'valuation' THEN (SELECT MIN(date) FROM valuation WHERE account_id = p_account_id)
      WHEN account_value_type(p_account_id) = 'transaction' THEN (SELECT MIN(effective_date) FROM transaction WHERE account_id = p_account_id)
      WHEN account_value_type(p_account_id) = 'investment_transaction' THEN (SELECT MIN(date) FROM investment_transaction WHERE account_id = p_account_id)
    END
$$ LANGUAGE SQL STABLE;


-- calculates balance info for every day of the account's lifetime
CREATE OR REPLACE FUNCTION calculate_account_balances(p_account_id int) RETURNS TABLE(account_id int, date date, balance bigint, inflows bigint, outflows bigint) AS $$
  WITH dates AS (
    SELECT generate_series(account_value_start_date(p_account_id), CURRENT_DATE, '1d')::date AS date
  )
  SELECT
    a.id AS account_id,
    d.date,
    CASE
      WHEN account_value_type(a.id) = 'valuation' THEN (SELECT v.amount FROM valuation v WHERE v.account_id = a.id AND v.date <= d.date ORDER BY v.date DESC LIMIT 1)
      WHEN account_value_type(a.id) = 'transaction' THEN a.current_balance + ((CASE WHEN at.classification = 'liability' THEN -1 ELSE 1 END) * SUM(COALESCE(SUM(t.amount), 0)) OVER w)
      WHEN account_value_type(a.id) = 'investment_transaction' THEN a.current_balance + ((CASE WHEN at.classification = 'liability' THEN -1 ELSE 1 END) * SUM(COALESCE(SUM(it.amount), 0)) OVER w)
    END AS balance,
    CASE
      WHEN account_value_type(a.id) = 'valuation' THEN NULL
      WHEN account_value_type(a.id) = 'transaction' THEN COALESCE(SUM(ABS(t.amount)) FILTER (WHERE t.type = 'INFLOW'), 0)
      WHEN account_value_type(a.id) = 'investment_transaction' THEN COALESCE(SUM(ABS(it.amount)) FILTER (WHERE it.type = 'INFLOW'), 0)
    END AS inflows,
    CASE
      WHEN account_value_type(a.id) = 'valuation' THEN NULL
      WHEN account_value_type(a.id) = 'transaction' THEN COALESCE(SUM(ABS(t.amount)) FILTER (WHERE t.type = 'OUTFLOW'), 0)
      WHEN account_value_type(a.id) = 'investment_transaction' THEN COALESCE(SUM(ABS(it.amount)) FILTER (WHERE it.type = 'OUTFLOW'), 0)
    END AS outflows
  FROM
    account a
    LEFT JOIN account_type at ON at.id = a.type_id
    CROSS JOIN dates d
    LEFT JOIN transaction t ON t.account_id = a.id AND t.effective_date = d.date
    LEFT JOIN investment_transaction it ON it.account_id = a.id AND it.date = d.date
  WHERE
    a.id = p_account_id
  GROUP BY
    a.id, at.classification, d.date
  WINDOW 
    w AS (ORDER BY d.date DESC)
$$ LANGUAGE SQL STABLE;
