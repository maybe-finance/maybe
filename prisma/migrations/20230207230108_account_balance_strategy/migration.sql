CREATE TYPE "AccountBalanceStrategy" AS ENUM ('current', 'available', 'sum', 'difference');

ALTER TABLE "account"
ADD COLUMN "available_balance_strategy" "AccountBalanceStrategy" NOT NULL DEFAULT 'available',
ADD COLUMN "current_balance_provider" DECIMAL(19,4),
ADD COLUMN "current_balance_strategy" "AccountBalanceStrategy" NOT NULL DEFAULT 'current';

-- attempt to undo the Plaid `current = current + available` logic we currently have in place
UPDATE "account"
SET
  "current_balance_provider" = (
    CASE
      WHEN "plaid_type" = 'investment' AND "current_balance" IS NOT NULL AND "available_balance" IS NOT NULL AND "current_balance" > "available_balance" THEN "current_balance" - "available_balance"
      ELSE "current_balance"
    END
  ),
  "current_balance_strategy" = (
    CASE
      WHEN "plaid_type" = 'investment' AND "current_balance" IS NOT NULL AND "available_balance" IS NOT NULL AND "current_balance" > "available_balance" THEN 'sum'
      ELSE 'current'
    END
  )::"AccountBalanceStrategy";

ALTER TABLE "account" DROP COLUMN "current_balance";

ALTER TABLE "account" RENAME COLUMN "available_balance" TO "available_balance_provider";
ALTER TABLE "account" ADD COLUMN "available_balance" DECIMAL(19,4) GENERATED ALWAYS AS (
	CASE "available_balance_strategy"
    WHEN 'current' THEN "current_balance_provider"
    WHEN 'available' THEN "available_balance_provider"
    WHEN 'sum' THEN "available_balance_provider" + "current_balance_provider"
    WHEN 'difference' THEN ABS("available_balance_provider" - "current_balance_provider")
	END
) STORED;

ALTER TABLE "account" ADD COLUMN "current_balance" DECIMAL(19,4) GENERATED ALWAYS AS (
	CASE "current_balance_strategy"
    WHEN 'current' THEN "current_balance_provider"
    WHEN 'available' THEN "available_balance_provider"
    WHEN 'sum' THEN "current_balance_provider" + "available_balance_provider"
    WHEN 'difference' THEN ABS("current_balance_provider" - "available_balance_provider")
	END
) STORED;

CREATE OR REPLACE FUNCTION valuation_changed() RETURNS TRIGGER LANGUAGE plpgsql AS $$
  BEGIN
    UPDATE account AS a
    SET
      start_date = account_value_start_date(a.id),
      current_balance_provider = (SELECT v.amount FROM valuation v WHERE v.account_id = a.id ORDER BY v.date DESC LIMIT 1)
    WHERE a.id = NEW.account_id OR a.id = OLD.account_id;
    RETURN NULL;
  END;
$$;
