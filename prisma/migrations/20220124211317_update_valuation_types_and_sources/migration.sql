-- Update generated column

ALTER TABLE "account" DROP COLUMN "valuation_source";

ALTER TABLE "account"
ADD COLUMN  "valuation_source" TEXT GENERATED ALWAYS AS (
	CASE 
    WHEN "valuation_type" = 'PLAID_TRANSACTION'
        OR "valuation_type" = 'PLAID_INVESTMENT_TRANSACTION'
        OR "valuation_type" = 'PLAID_VALUATION'
        THEN 'plaid'
    WHEN "valuation_type" = 'USER_VALUATION' THEN 'user'
    WHEN "valuation_type" = 'KBB_VALUATION' THEN 'kbb'
    WHEN "valuation_type" = 'ZILLOW_VALUATION' THEN 'zillow'
		ELSE 'other'
	END
) STORED;

ALTER TABLE "account" ALTER COLUMN "valuation_source" SET NOT NULL;