/*
  Warnings:

  - A unique constraint covering the columns `[account_connection_id,finicity_account_id]` on the table `account` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[finicity_holding_id]` on the table `holding` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[finicity_transaction_id]` on the table `investment_transaction` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[finicity_transaction_id]` on the table `transaction` will be added. If there are existing duplicate values, this will fail.
  - Changed the type of `type` on the `account` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `valuation_method` on the `account` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `valuation_source` on the `account` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `type` on the `account_connection` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "AccountConnectionType" AS ENUM ('plaid', 'finicity');

-- CreateEnum
CREATE TYPE "AccountType" AS ENUM ('plaid', 'finicity', 'property', 'vehicle', 'other');

-- CreateEnum
CREATE TYPE "ValuationSource" AS ENUM ('PLAID', 'FINICITY', 'KBB', 'ZILLOW', 'USER');

-- CreateEnum
CREATE TYPE "ValuationMethod" AS ENUM ('TRANSACTION', 'INVESTMENT_TRANSACTION', 'VALUATION');

-- AlterTable
ALTER TABLE "account"
ADD COLUMN "finicity_account_id" TEXT,
ADD COLUMN "finicity_detail" JSONB,
ADD COLUMN "finicity_type" TEXT,
DROP COLUMN "valuation_method",
DROP COLUMN "valuation_source",
DROP COLUMN "category",
DROP COLUMN "subcategory";

ALTER TABLE "account" ALTER COLUMN "type" TYPE "AccountType" USING "type"::"AccountType";

-- Due to a limitation in postgres, we must recreate the enum if we're going to use the new values in this transaction (instead of `ALTER TYPE <enum_name> ADD VALUE <new_value>`).
ALTER TYPE "ValuationType" RENAME TO "ValuationType_old";
CREATE TYPE "ValuationType" AS ENUM ('PLAID_TRANSACTION', 'PLAID_INVESTMENT_TRANSACTION', 'PLAID_VALUATION', 'FINICITY_TRANSACTION', 'FINICITY_INVESTMENT_TRANSACTION', 'KBB_VALUATION', 'ZILLOW_VALUATION', 'USER_VALUATION');
ALTER TABLE "account" ALTER COLUMN "valuation_type" TYPE "ValuationType" USING "valuation_type"::text::"ValuationType";
DROP TYPE "ValuationType_old";

-- update valuation_method
ALTER TABLE "account"
ADD COLUMN  "valuation_method" "ValuationMethod" GENERATED ALWAYS AS (
	CASE 
		WHEN "valuation_type" IN ('PLAID_TRANSACTION', 'FINICITY_TRANSACTION') THEN 'TRANSACTION'::"ValuationMethod"
    WHEN "valuation_type" IN ('PLAID_INVESTMENT_TRANSACTION', 'FINICITY_INVESTMENT_TRANSACTION') THEN 'INVESTMENT_TRANSACTION'::"ValuationMethod"
    WHEN "valuation_type" IN ('PLAID_VALUATION', 'KBB_VALUATION', 'ZILLOW_VALUATION', 'USER_VALUATION') THEN 'VALUATION'::"ValuationMethod"
	END
) STORED;
ALTER TABLE "account" ALTER COLUMN "valuation_method" SET NOT NULL;

-- update valuation_source
ALTER TABLE "account"
ADD COLUMN  "valuation_source" "ValuationSource" GENERATED ALWAYS AS (
	CASE 
    WHEN "valuation_type" IN ('PLAID_TRANSACTION', 'PLAID_INVESTMENT_TRANSACTION', 'PLAID_VALUATION') THEN 'PLAID'::"ValuationSource"
    WHEN "valuation_type" IN ('FINICITY_TRANSACTION', 'FINICITY_INVESTMENT_TRANSACTION') THEN 'FINICITY'::"ValuationSource"
    WHEN "valuation_type" = 'KBB_VALUATION' THEN 'KBB'::"ValuationSource"
    WHEN "valuation_type" = 'ZILLOW_VALUATION' THEN 'ZILLOW'::"ValuationSource"
    WHEN "valuation_type" = 'USER_VALUATION' THEN 'USER'::"ValuationSource"
	END
) STORED;
ALTER TABLE "account" ALTER COLUMN "valuation_source" SET NOT NULL;

-- update category
ALTER TABLE "account"
ADD COLUMN  "category" TEXT GENERATED ALWAYS AS (
	CASE 
		WHEN "type" = 'plaid' AND "plaid_type" IN ('depository') THEN 'cash'
		WHEN "type" = 'plaid' AND "plaid_type" IN ('investment' ,'brokerage') THEN 'investment'
		WHEN "type" = 'plaid' AND "plaid_type" IN ('loan') THEN 'loan'
		WHEN "type" = 'plaid' AND "plaid_type" IN ('credit') THEN 'credit'
		WHEN "type" = 'property' THEN 'property'
		WHEN "type" = 'vehicle' THEN 'vehicle'
		ELSE 'other'
	END
) STORED;
ALTER TABLE "account" ALTER COLUMN "category" SET NOT NULL;

-- update subcategory
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
ALTER TABLE "account" ALTER COLUMN "subcategory" SET NOT NULL;

-- AlterTable
ALTER TABLE "account_connection" 
ADD COLUMN "finicity_institution_id" TEXT,
ADD COLUMN "finicity_institution_login_id" TEXT;

ALTER TABLE "account_connection" ALTER COLUMN "type" TYPE "AccountConnectionType" USING "type"::"AccountConnectionType";

-- AlterTable
ALTER TABLE "holding" ADD COLUMN "finicity_holding_id" TEXT;

-- AlterTable
ALTER TABLE "investment_transaction" 
ADD COLUMN "finicity_investment_transaction_type" TEXT,
ADD COLUMN "finicity_transaction_id" TEXT;

-- AlterTable
ALTER TABLE "transaction" 
ADD COLUMN "finicity_categorization" JSONB,
ADD COLUMN "finicity_transaction_id" TEXT,
ADD COLUMN "finicity_type" TEXT;

-- AlterTable
ALTER TABLE "user" ADD COLUMN "finicity_customer_id" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "account_account_connection_id_finicity_account_id_key" ON "account"("account_connection_id", "finicity_account_id");

-- CreateIndex
CREATE UNIQUE INDEX "holding_finicity_holding_id_key" ON "holding"("finicity_holding_id");

-- CreateIndex
CREATE UNIQUE INDEX "investment_transaction_finicity_transaction_id_key" ON "investment_transaction"("finicity_transaction_id");

-- CreateIndex
CREATE UNIQUE INDEX "transaction_finicity_transaction_id_key" ON "transaction"("finicity_transaction_id");
