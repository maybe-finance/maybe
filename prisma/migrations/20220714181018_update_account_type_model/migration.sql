BEGIN;

-- Make the provider subcategory field optional rather than generated
ALTER TABLE "account" ADD COLUMN "subcategory_provider_new" TEXT;
ALTER TABLE "account" RENAME COLUMN "subcategory_provider" TO "subcategory_provider_old";
UPDATE "account" SET "subcategory_provider_new" = "subcategory_provider_old";
ALTER TABLE "account" RENAME COLUMN "subcategory_provider_new" TO "subcategory_provider";
ALTER TABLE "account" DROP COLUMN "subcategory_provider_old";

CREATE TYPE "AccountType_new" AS ENUM ('INVESTMENT', 'DEPOSITORY', 'CREDIT', 'LOAN', 'PROPERTY', 'VEHICLE', 'OTHER_ASSET', 'OTHER_LIABILITY');
ALTER TABLE "account" ADD COLUMN "type_new" "AccountType_new";

UPDATE "account" 
SET "type_new" = CASE 
  WHEN "type" IN ('vehicle', 'property') THEN UPPER("type"::text)::"AccountType_new"
	WHEN "valuation_method" = 'TRANSACTION' AND "classification" = 'asset' THEN 'DEPOSITORY'
	WHEN "valuation_method" = 'INVESTMENT_TRANSACTION' THEN 'INVESTMENT'
	WHEN "type" = 'finicity' AND "finicity_type" = 'creditCard' THEN 'CREDIT'
	WHEN "type" = 'finicity' AND "finicity_type" <> 'creditCard' THEN 'LOAN'
	WHEN "type" = 'plaid' AND "plaid_liability" -> 'credit' IS NOT NULL THEN 'CREDIT'
	WHEN "type" = 'plaid' AND "plaid_liability" -> 'mortgage' IS NOT NULL THEN 'LOAN'
	WHEN "type" = 'plaid' AND "plaid_liability" -> 'student' IS NOT NULL THEN 'LOAN'
	WHEN "type" = 'plaid' AND "plaid_type" = 'credit' THEN 'CREDIT'
	WHEN "type" = 'plaid' AND "plaid_type" = 'loan' THEN 'LOAN'
  WHEN "type" = 'other' AND "category" = 'loan' THEN 'LOAN'
	WHEN "type" = 'other' AND "category" = 'credit' THEN 'CREDIT'
	WHEN "type" = 'other' AND "classification" = 'asset' THEN 'OTHER_ASSET'
	WHEN "type" = 'other' AND "classification" = 'liability' THEN 'OTHER_LIABILITY'
END;

ALTER TABLE "account" ALTER COLUMN "type_new" SET NOT NULL;
ALTER TABLE "account" DROP COLUMN "valuation_method";
ALTER TABLE "account" DROP COLUMN "valuation_type";
DROP TYPE "ValuationMethod";
DROP TYPE "ValuationType";

-- Recreate subcategory
ALTER TABLE "account" ADD COLUMN "subcategory_new" TEXT NOT NULL GENERATED ALWAYS AS (
  COALESCE(subcategory_user, subcategory_provider, 'other')
) STORED;
ALTER TABLE "account" RENAME COLUMN "subcategory" TO "subcategory_old";
ALTER TABLE "account" RENAME COLUMN "subcategory_new" TO "subcategory";
ALTER TABLE "account" DROP COLUMN "subcategory_old";

-- Restore type
ALTER TABLE "account" RENAME COLUMN "type" TO "type_old";
ALTER TABLE "account" RENAME COLUMN "type_new" TO "type";
ALTER TABLE "account" DROP COLUMN "type_old";
ALTER TYPE "AccountType" RENAME TO "AccountType_old";
ALTER TYPE "AccountType_new" RENAME TO "AccountType";
DROP TYPE "AccountType_old";

-- Make our classification column auto-generated
ALTER TABLE "account"
ADD COLUMN "classification_new" "AccountClassification" GENERATED ALWAYS AS (
  CASE
    WHEN "type" IN ('INVESTMENT', 'DEPOSITORY', 'PROPERTY', 'VEHICLE', 'OTHER_ASSET') THEN 'asset'::"AccountClassification"
    WHEN "type" IN ('CREDIT', 'LOAN', 'OTHER_LIABILITY') THEN 'liability'::"AccountClassification"
  END
) STORED;

ALTER TABLE "account" RENAME COLUMN "classification" TO "classification_old";
ALTER TABLE "account" RENAME COLUMN "classification_new" TO "classification";
ALTER TABLE "account" ALTER COLUMN "classification" SET NOT NULL;
ALTER TABLE "account" DROP COLUMN "classification_old";

COMMIT;