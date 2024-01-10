-- no longer used
DROP FUNCTION IF EXISTS account_value_type;

-- default to today's date if we don't have any transactions/valuations for the account so it plays nicely with time_bucket_gapfill
CREATE OR REPLACE FUNCTION account_value_start_date(p_account_id integer) RETURNS date STABLE AS $$
  SELECT
    COALESCE(
      CASE
        WHEN a.valuation_method = 'valuation' THEN (SELECT MIN(date) FROM valuation WHERE account_id = p_account_id)
        WHEN a.valuation_method = 'transaction' THEN (SELECT MIN(date) FROM transaction WHERE account_id = p_account_id)
        WHEN a.valuation_method = 'investment-transaction' THEN (SELECT MIN(date) FROM investment_transaction WHERE account_id = p_account_id)
        ELSE NULL
      END, now())
  FROM
    account a
  WHERE
    a.id = p_account_id
$$ LANGUAGE SQL;