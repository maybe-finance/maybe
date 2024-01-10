-- update fn to fallback to the account creation date rather than `now()`
CREATE OR REPLACE FUNCTION public.account_value_start_date(p_account_id integer) RETURNS date LANGUAGE sql STABLE AS $$
  SELECT
    COALESCE(
      LEAST(
        (a.loan->>'originationDate')::date,
        (SELECT MIN(date) FROM "transaction" where "account_id" = a.id),
        (SELECT MIN(date) FROM "valuation" where "account_id" = a.id),
        (SELECT MIN(date) FROM "investment_transaction" where "account_id" = a.id)
      ),
      a.created_at::date -- fallback to using the date the account was added
    )
  FROM
    account a
  WHERE
    a.id = p_account_id
$$;
