/*
  Warnings:

  - The values [finicity] on the enum `AccountConnectionType` will be removed. If these variants are still used in the database, this will fail.
  - The values [finicity] on the enum `AccountProvider` will be removed. If these variants are still used in the database, this will fail.
  - The values [FINICITY] on the enum `Provider` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `finicity_account_id` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_detail` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_type` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_error` on the `account_connection` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_institution_id` on the `account_connection` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_institution_login_id` on the `account_connection` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_position_id` on the `holding` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_investment_transaction_type` on the `investment_transaction` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_transaction_id` on the `investment_transaction` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_asset_class` on the `security` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_fi_asset_class` on the `security` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_security_id` on the `security` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_security_id_type` on the `security` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_type` on the `security` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_categorization` on the `transaction` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_transaction_id` on the `transaction` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_type` on the `transaction` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_customer_id` on the `user` table. All the data in the column will be lost.
  - You are about to drop the column `finicity_username` on the `user` table. All the data in the column will be lost.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "AccountConnectionType_new" AS ENUM ('plaid', 'teller');
ALTER TABLE "account_connection" ALTER COLUMN "type" TYPE "AccountConnectionType_new" USING ("type"::text::"AccountConnectionType_new");
ALTER TYPE "AccountConnectionType" RENAME TO "AccountConnectionType_old";
ALTER TYPE "AccountConnectionType_new" RENAME TO "AccountConnectionType";
DROP TYPE "AccountConnectionType_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "AccountProvider_new" AS ENUM ('user', 'plaid', 'teller');
ALTER TABLE "account" ALTER COLUMN "provider" TYPE "AccountProvider_new" USING ("provider"::text::"AccountProvider_new");
ALTER TYPE "AccountProvider" RENAME TO "AccountProvider_old";
ALTER TYPE "AccountProvider_new" RENAME TO "AccountProvider";
DROP TYPE "AccountProvider_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "Provider_new" AS ENUM ('PLAID', 'TELLER');
ALTER TABLE "provider_institution" ALTER COLUMN "provider" TYPE "Provider_new" USING ("provider"::text::"Provider_new");
ALTER TYPE "Provider" RENAME TO "Provider_old";
ALTER TYPE "Provider_new" RENAME TO "Provider";
DROP TYPE "Provider_old";
COMMIT;

-- DropIndex
DROP INDEX "account_account_connection_id_finicity_account_id_key";

-- DropIndex
DROP INDEX "holding_finicity_position_id_key";

-- DropIndex
DROP INDEX "investment_transaction_finicity_transaction_id_key";

-- DropIndex
DROP INDEX "security_finicity_security_id_finicity_security_id_type_key";

-- DropIndex
DROP INDEX "transaction_finicity_transaction_id_key";

-- DropIndex
DROP INDEX "user_finicity_customer_id_key";

-- DropIndex
DROP INDEX "user_finicity_username_key";

-- AlterTable
ALTER TABLE "account" DROP COLUMN "finicity_account_id",
DROP COLUMN "finicity_detail",
DROP COLUMN "finicity_type";

-- AlterTable
ALTER TABLE "account_connection" DROP COLUMN "finicity_error",
DROP COLUMN "finicity_institution_id",
DROP COLUMN "finicity_institution_login_id";

-- AlterTable
ALTER TABLE "holding" DROP COLUMN "finicity_position_id";

-- AlterTable
ALTER TABLE "investment_transaction" DROP COLUMN "finicity_investment_transaction_type",
DROP COLUMN "finicity_transaction_id";

-- AlterTable
ALTER TABLE "security" DROP COLUMN "finicity_asset_class",
DROP COLUMN "finicity_fi_asset_class",
DROP COLUMN "finicity_security_id",
DROP COLUMN "finicity_security_id_type",
DROP COLUMN "finicity_type";

-- AlterTable
ALTER TABLE "transaction" DROP COLUMN "finicity_categorization",
DROP COLUMN "finicity_transaction_id",
DROP COLUMN "finicity_type";

-- AlterTable
ALTER TABLE "user" DROP COLUMN "finicity_customer_id",
DROP COLUMN "finicity_username";
