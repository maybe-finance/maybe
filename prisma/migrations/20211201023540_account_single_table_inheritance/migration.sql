-- DropForeignKey
ALTER TABLE "account" DROP CONSTRAINT "account_subtype_id_fkey";

-- DropForeignKey
ALTER TABLE "account" DROP CONSTRAINT "account_type_id_fkey";

-- DropForeignKey
ALTER TABLE "account_subtype" DROP CONSTRAINT "account_subtype_account_type_id_fkey";

-- DropIndex
DROP INDEX "account_subtype_id_idx";

-- DropIndex
DROP INDEX "account_type_id_idx";

-- First, add the new columns
ALTER TABLE account
ADD COLUMN classification "AccountClassification",
ADD COLUMN "type" TEXT,
ADD COLUMN "valuation_type" TEXT,
ADD COLUMN "subcategory_override" TEXT;

ALTER TABLE account
RENAME COLUMN "house_meta" TO "property_meta";

-- Update all `Account.type` fields
UPDATE "account" SET "type" = 'plaid' WHERE plaid_account_id IS NOT NULL;
UPDATE "account" SET "type" = 'property' WHERE property_meta IS NOT NULL;

-- Update all `Account.classification` fields
UPDATE "account" a
SET classification = at.classification
FROM "account_type" at
WHERE a.type_id = at.id;

-- Update all `Account.valuation_type` fields
UPDATE "account"
SET "valuation_type" = 'plaid-investment-transaction'
WHERE "plaid_type" = 'investment';

UPDATE "account"
SET "valuation_type" = 'plaid-transaction'
WHERE "plaid_type" <> 'investment' AND "plaid_type" IS NOT NULL;

UPDATE "account"
SET "valuation_type" = 'zillow-valuation'
WHERE "plaid_type" IS NULL;

-- Add computed column for category
ALTER TABLE "account"
ADD COLUMN  "category" TEXT GENERATED ALWAYS AS (
	CASE 
		WHEN "type" = 'plaid' AND "plaid_type" IN ('depository') THEN 'cash'
		WHEN "type" = 'plaid' AND "plaid_type" IN ('investment' ,'brokerage') THEN 'investment'
		WHEN "type" = 'plaid' AND "plaid_type" IN ('loan') THEN 'loan'
		WHEN "type" = 'plaid' AND "plaid_type" IN ('credit') THEN 'credit'
		WHEN "type" = 'property' THEN 'property'
		WHEN "type" = 'vehicle' THEN 'vehicle'
		WHEN "type" = 'other' THEN 'other'
	END
) STORED;

-- Add computed column for subcategory
ALTER TABLE "account"
ADD COLUMN  "subcategory" TEXT GENERATED ALWAYS AS (
	CASE 
		WHEN "subcategory_override" IS NOT NULL THEN "subcategory_override"
		WHEN "type" = 'plaid' THEN "plaid_subtype"
		WHEN "type" = 'property' THEN 'property'
		WHEN "type" = 'vehicle' THEN 'vehicle'
		ELSE 'other'
	END
) STORED;


ALTER TABLE "account"
ALTER COLUMN "type" SET NOT NULL,
ALTER COLUMN "classification" SET NOT NULL,
ALTER COLUMN "valuation_type" SET NOT NULL,
ALTER COLUMN "category" SET NOT NULL,
ALTER COLUMN "subcategory" SET NOT NULL;

ALTER TABLE "account"
DROP COLUMN "subtype_id",
DROP COLUMN "type_id";

-- DropTable
DROP TABLE "account_subtype";

-- DropTable
DROP TABLE "account_type";