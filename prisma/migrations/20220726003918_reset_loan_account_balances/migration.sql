-- remove stale account balance records now that new calculation is in place
DELETE FROM account_balance
WHERE account_id IN (SELECT id FROM account WHERE type = 'LOAN' AND (loan_provider IS NOT NULL OR loan_user IS NOT NULL));

-- remove stale valuations for accounts that have proper loan data
DELETE FROM valuation
WHERE account_id IN (SELECT id FROM account WHERE type = 'LOAN' AND (loan_provider IS NOT NULL OR loan_user IS NOT NULL));

-- update function to use loan origination date
CREATE OR REPLACE FUNCTION public.account_value_start_date(p_account_id integer) RETURNS date LANGUAGE sql STABLE AS $$
  SELECT
    LEAST(
      (a.loan->>'originationDate')::date,     
      (SELECT MIN(date) FROM "transaction" where "account_id" = a.id),
	    (SELECT MIN(date) FROM "valuation" where "account_id" = a.id),
	    (SELECT MIN(date) FROM "investment_transaction" where "account_id" = a.id),
	    now()
    )
  FROM
    account a
  WHERE
    a.id = p_account_id
$$;