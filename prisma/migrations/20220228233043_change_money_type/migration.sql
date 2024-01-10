-- AlterTable
ALTER TABLE "account" ALTER COLUMN "current_balance" SET DATA TYPE DECIMAL(19,4) USING current_balance::numeric / 100;
ALTER TABLE "account" ALTER COLUMN "available_balance" SET DATA TYPE DECIMAL(19,4) USING available_balance::numeric / 100;

-- AlterTable
ALTER TABLE "account_balance" ALTER COLUMN "balance" SET DATA TYPE DECIMAL(19,4) USING balance::numeric / 100;
ALTER TABLE "account_balance" ALTER COLUMN "inflows" SET DEFAULT 0;
ALTER TABLE "account_balance" ALTER COLUMN "inflows" SET DATA TYPE DECIMAL(19,4) USING inflows::numeric / 100;
ALTER TABLE "account_balance" ALTER COLUMN "outflows" SET DEFAULT 0;
ALTER TABLE "account_balance" ALTER COLUMN "outflows" SET DATA TYPE DECIMAL(19,4) USING outflows::numeric / 100;

-- AlterTable
ALTER TABLE "holding" ALTER COLUMN "value" SET DATA TYPE DECIMAL(19,4) USING value::numeric / 100;
ALTER TABLE "holding" ALTER COLUMN "cost_basis" SET DATA TYPE DECIMAL(23,8) USING cost_basis::numeric / 100;
ALTER TABLE "holding" ALTER COLUMN "price" SET DATA TYPE DECIMAL(23,8) USING price::numeric / 100;

-- AlterTable
ALTER TABLE "transaction" DROP COLUMN "type";
ALTER TABLE "transaction" ALTER COLUMN "amount" SET DATA TYPE DECIMAL(19,4) USING amount::numeric / 100;
ALTER TABLE "transaction" ADD COLUMN "type" "TransactionType" NOT NULL GENERATED ALWAYS AS (CASE WHEN amount < 0 THEN 'INFLOW'::"TransactionType" ELSE 'OUTFLOW'::"TransactionType" END) STORED;

-- AlterTable
ALTER TABLE "investment_transaction" DROP COLUMN "type";
ALTER TABLE "investment_transaction" ALTER COLUMN "amount" SET DATA TYPE DECIMAL(19,4) USING amount::numeric / 100;
ALTER TABLE "investment_transaction" ALTER COLUMN "price" SET DATA TYPE DECIMAL(23,8) USING price::numeric / 100;
ALTER TABLE "investment_transaction" ADD COLUMN "type" "TransactionType" NOT NULL GENERATED ALWAYS AS (CASE WHEN amount < 0 THEN 'INFLOW'::"TransactionType" ELSE 'OUTFLOW'::"TransactionType" END) STORED;

-- AlterTable
ALTER TABLE "security_pricing" ALTER COLUMN "price_close" SET DATA TYPE DECIMAL(23,8);

-- AlterTable
ALTER TABLE "valuation" ALTER COLUMN "amount" SET DATA TYPE DECIMAL(19,4) USING amount::numeric / 100;

-- Update functions
DROP FUNCTION IF EXISTS calculate_account_balances;
DROP FUNCTION IF EXISTS account_balances_gapfilled(date,date,interval,integer[]);
CREATE OR REPLACE FUNCTION public.account_balances_gapfilled(p_start date, p_end date, p_interval interval, p_account_ids integer[])
 RETURNS TABLE(account_id integer, date date, balance numeric)
 LANGUAGE sql
 STABLE
AS $$
  WITH account_balances_gapfilled AS (
    -- fill in balance for start of range
    (
      SELECT
        ab.account_id,
        p_start::date AS date,
        last(ab.balance, ab.date) AS balance
      FROM
        account_balance ab
      WHERE
        ab.account_id = ANY(p_account_ids)
        AND ab.date <= p_start
      GROUP BY
        ab.account_id
    )
    UNION
    -- fill in balance for end of range
    (
      SELECT
        ab.account_id,
        p_end::date AS date,
        last(ab.balance, ab.date) AS balance
      FROM
        account_balance ab
      WHERE
        ab.account_id = ANY(p_account_ids)
        AND ab.date <= p_end
      GROUP BY
        ab.account_id
    )
    UNION
    -- this gapfill covers accounts who have at least 1 balance record in the range
    (
      SELECT
        ab.account_id,
        time_bucket_gapfill(p_interval, ab.date) AS date,
        locf(
          first(ab.balance, ab.date),
          COALESCE(
            (SELECT balance FROM account_balance WHERE date < p_start AND account_id = ab.account_id ORDER BY date DESC LIMIT 1),
            (SELECT balance FROM account_balance WHERE account_id = ab.account_id ORDER BY date ASC LIMIT 1)
          )
        ) AS balance
      FROM
        account_balance ab
      WHERE
        ab.account_id = ANY(p_account_ids)
        AND ab.date BETWEEN p_start AND p_end
      GROUP BY
        1, 2
    )
    UNION
    -- this gapfill covers accounts that either (a) have balance records outside range OR (b) don't have any balance records
    (
      SELECT
        ab.account_id,
        time_bucket_gapfill(p_interval, ab.date, p_start, (p_end::date + interval '1d')::date) AS date,
        locf(first(ab.balance, ab.date)) AS balance
      FROM (
        SELECT
          fb.account_id,
          p_start::date AS date,
          fb.balance
        FROM (
          SELECT
            a.id AS account_id,
            COALESCE(
              (SELECT balance FROM account_balance WHERE account_id = a.id AND date < p_start ORDER BY date DESC LIMIT 1),
              (SELECT balance FROM account_balance WHERE account_id = a.id AND date > p_end ORDER BY date ASC LIMIT 1),
              a.current_balance
            ) AS balance
          FROM
            account a
          WHERE
            a.id = ANY(p_account_ids)
            AND a.id NOT IN (SELECT DISTINCT account_id FROM account_balance WHERE date BETWEEN p_start AND p_end)
        ) fb
      ) ab
      GROUP BY
        1, 2
    )
  )
  SELECT DISTINCT ON (abg.account_id, abg.date)
    abg.account_id,
    abg.date,
    CASE
      WHEN a.start_date IS NOT NULL AND abg.date < a.start_date THEN 0
      ELSE COALESCE(abg.balance, 0)
    END AS balance
  FROM
    account_balances_gapfilled abg
    INNER JOIN account a ON a.id = abg.account_id
  WHERE
    abg.date BETWEEN p_start AND p_end
$$;