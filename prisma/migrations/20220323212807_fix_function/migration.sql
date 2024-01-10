CREATE OR REPLACE FUNCTION public.account_value_start_date(p_account_id integer) RETURNS date LANGUAGE sql STABLE AS $$
  SELECT
    COALESCE(
      CASE
        WHEN a.valuation_method = 'VALUATION' THEN (SELECT MIN(date) FROM valuation WHERE account_id = p_account_id)
        WHEN a.valuation_method = 'TRANSACTION' THEN (SELECT MIN(date) - 1 FROM transaction WHERE account_id = p_account_id)
        WHEN a.valuation_method = 'INVESTMENT_TRANSACTION' THEN (SELECT MIN(date) - 1 FROM investment_transaction WHERE account_id = p_account_id)
        ELSE NULL
      END, now())
  FROM
    account a
  WHERE
    a.id = p_account_id
$$;


CREATE OR REPLACE FUNCTION valuation_changed() RETURNS TRIGGER LANGUAGE plpgsql AS $$
  BEGIN
    UPDATE account AS a
    SET
      start_date = account_value_start_date(a.id),
      current_balance = (SELECT v.amount FROM valuation v WHERE v.account_id = a.id ORDER BY v.date DESC LIMIT 1)
    WHERE
      (a.id = NEW.account_id OR a.id = OLD.account_id)
      AND a.valuation_method = 'VALUATION';
    RETURN NULL;
  END;
$$;