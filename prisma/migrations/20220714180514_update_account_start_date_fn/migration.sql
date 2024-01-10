CREATE OR REPLACE FUNCTION public.account_value_start_date(p_account_id integer) RETURNS date LANGUAGE sql STABLE AS $$
  SELECT
    LEAST(
      (SELECT MIN(date) FROM "transaction" where "account_id" = p_account_id),
	    (SELECT MIN(date) FROM "valuation" where "account_id" = p_account_id),
	    (SELECT MIN(date) FROM "investment_transaction" where "account_id" = p_account_id),
	    now()
    )
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
    WHERE a.id = NEW.account_id OR a.id = OLD.account_id;
    RETURN NULL;
  END;
$$;