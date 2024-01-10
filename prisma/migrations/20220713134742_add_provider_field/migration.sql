CREATE TYPE "AccountProvider" AS ENUM ('user', 'plaid', 'finicity');

ALTER TABLE "account" ADD COLUMN "provider" "AccountProvider";

UPDATE "account" set "provider" = LOWER("valuation_source"::text)::"AccountProvider";

ALTER TABLE "account"
  ALTER COLUMN "provider" SET NOT NULL,
  DROP COLUMN "valuation_source";
  
DROP TYPE "ValuationSource";