/*
  Warnings:

  - The values [plaid] on the enum `AccountConnectionType` will be removed. If these variants are still used in the database, this will fail.
  - The values [plaid] on the enum `AccountProvider` will be removed. If these variants are still used in the database, this will fail.
  - The values [PLAID] on the enum `Provider` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `plaid_account_id` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_liability` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_subtype` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_type` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_access_token` on the `account_connection` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_consent_expiration` on the `account_connection` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_error` on the `account_connection` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_institution_id` on the `account_connection` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_item_id` on the `account_connection` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_new_accounts_available` on the `account_connection` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_holding_id` on the `holding` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_investment_transaction_id` on the `investment_transaction` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_subtype` on the `investment_transaction` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_type` on the `investment_transaction` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_is_cash_equivalent` on the `security` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_security_id` on the `security` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_type` on the `security` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_category` on the `transaction` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_category_id` on the `transaction` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_personal_finance_category` on the `transaction` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_transaction_id` on the `transaction` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_link_token` on the `user` table. All the data in the column will be lost.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "AccountConnectionType_new" AS ENUM ('teller');
ALTER TABLE "account_connection" ALTER COLUMN "type" TYPE "AccountConnectionType_new" USING ("type"::text::"AccountConnectionType_new");
ALTER TYPE "AccountConnectionType" RENAME TO "AccountConnectionType_old";
ALTER TYPE "AccountConnectionType_new" RENAME TO "AccountConnectionType";
DROP TYPE "AccountConnectionType_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "AccountProvider_new" AS ENUM ('user', 'teller');
ALTER TABLE "account" ALTER COLUMN "provider" TYPE "AccountProvider_new" USING ("provider"::text::"AccountProvider_new");
ALTER TYPE "AccountProvider" RENAME TO "AccountProvider_old";
ALTER TYPE "AccountProvider_new" RENAME TO "AccountProvider";
DROP TYPE "AccountProvider_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "Provider_new" AS ENUM ('TELLER');
ALTER TABLE "provider_institution" ALTER COLUMN "provider" TYPE "Provider_new" USING ("provider"::text::"Provider_new");
ALTER TYPE "Provider" RENAME TO "Provider_old";
ALTER TYPE "Provider_new" RENAME TO "Provider";
DROP TYPE "Provider_old";
COMMIT;

-- DropIndex
DROP INDEX "account_account_connection_id_plaid_account_id_key";

-- DropIndex
DROP INDEX "account_connection_plaid_item_id_key";

-- DropIndex
DROP INDEX "holding_plaid_holding_id_key";

-- DropIndex
DROP INDEX "investment_transaction_plaid_investment_transaction_id_key";

-- DropIndex
DROP INDEX "security_plaid_security_id_key";

-- DropIndex
DROP INDEX "transaction_plaid_transaction_id_key";

-- AlterTable
ALTER TABLE "account" DROP COLUMN "plaid_account_id",
DROP COLUMN "plaid_liability",
DROP COLUMN "plaid_subtype",
DROP COLUMN "plaid_type";

-- AlterTable
ALTER TABLE "account_connection" DROP COLUMN "plaid_access_token",
DROP COLUMN "plaid_consent_expiration",
DROP COLUMN "plaid_error",
DROP COLUMN "plaid_institution_id",
DROP COLUMN "plaid_item_id",
DROP COLUMN "plaid_new_accounts_available";

-- AlterTable
ALTER TABLE "holding" DROP COLUMN "plaid_holding_id";

-- AlterTable
ALTER TABLE "investment_transaction" DROP COLUMN "plaid_investment_transaction_id",
DROP COLUMN "plaid_subtype",
DROP COLUMN "plaid_type";

-- AlterTable
ALTER TABLE "security" DROP COLUMN "plaid_is_cash_equivalent",
DROP COLUMN "plaid_security_id",
DROP COLUMN "plaid_type";

-- AlterTable
ALTER TABLE "transaction" DROP COLUMN "plaid_category",
DROP COLUMN "plaid_category_id",
DROP COLUMN "plaid_personal_finance_category",
DROP COLUMN "plaid_transaction_id";

-- AlterTable
ALTER TABLE "user" DROP COLUMN "plaid_link_token";
