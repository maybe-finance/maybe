
-- CreateEnum
CREATE TYPE "ValuationType" AS ENUM ('PLAID_TRANSACTION', 'PLAID_INVESTMENT_TRANSACTION', 'KBB_VALUATION', 'ZILLOW_VALUATION', 'USER_VALUATION');

-- Integrate new enum
ALTER TABLE "account"
ALTER "valuation_type" DROP NOT NULL;

UPDATE "account"
SET "valuation_type" = NULL;

ALTER TABLE "account"
DROP COLUMN "valuation_type",
ADD COLUMN "valuation_type" "ValuationType";

-- Populate enums
UPDATE "account"
SET "valuation_type" = 'PLAID_TRANSACTION'
WHERE "type" = 'plaid' AND "plaid_type" <> 'investment';

UPDATE "account"
SET "valuation_type" = 'PLAID_INVESTMENT_TRANSACTION'
WHERE "type" = 'plaid' AND "plaid_type" = 'investment';

UPDATE "account"
SET "valuation_type" = 'USER_VALUATION'
WHERE "type" <> 'plaid';

-- Add generated columns
ALTER TABLE "account"
ADD COLUMN  "valuation_source" TEXT GENERATED ALWAYS AS (
	CASE 
		WHEN "valuation_type" = 'PLAID_TRANSACTION' OR "valuation_type" = 'PLAID_INVESTMENT_TRANSACTION' THEN 'plaid'
    WHEN "valuation_type" = 'USER_VALUATION' THEN 'user'
    WHEN "valuation_type" = 'KBB_VALUATION' THEN 'kbb'
    WHEN "valuation_type" = 'ZILLOW_VALUATION' THEN 'zillow'
		ELSE 'other'
	END
) STORED;

ALTER TABLE "account"
ADD COLUMN  "valuation_method" TEXT GENERATED ALWAYS AS (
	CASE 
		WHEN "valuation_type" = 'PLAID_TRANSACTION' THEN 'transaction'
    WHEN "valuation_type" = 'PLAID_INVESTMENT_TRANSACTION' THEN 'investment-transaction'
    ELSE 'valuation'
	END
) STORED;

-- Add non-null constraints
ALTER TABLE "account"
ALTER COLUMN "valuation_method" SET NOT NULL,
ALTER COLUMN "valuation_source" SET NOT NULL,
ALTER COLUMN "valuation_type" SET NOT NULL;
