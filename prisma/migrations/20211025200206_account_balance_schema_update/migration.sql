/*
  Warnings:

  - You are about to drop the column `iso_currency_code` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_subtype` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_type` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `unofficial_currency_code` on the `account` table. All the data in the column will be lost.
  - You are about to drop the column `closing_balance` on the `account_balance` table. All the data in the column will be lost.
  - You are about to drop the column `credit_amount` on the `account_balance` table. All the data in the column will be lost.
  - You are about to drop the column `debit_amount` on the `account_balance` table. All the data in the column will be lost.
  - You are about to drop the column `quantity` on the `account_balance` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_institution_id` on the `account_connection` table. All the data in the column will be lost.
  - You are about to drop the column `iso_currency_code` on the `transaction` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_category_id` on the `transaction` table. All the data in the column will be lost.
  - You are about to drop the column `plaid_transaction_id` on the `transaction` table. All the data in the column will be lost.
  - You are about to drop the column `unofficial_currency_code` on the `transaction` table. All the data in the column will be lost.
  - Added the required column `currency_code` to the `account` table without a default value. This is not possible if the table is not empty.
  - Added the required column `balance` to the `account_balance` table without a default value. This is not possible if the table is not empty.
  - Added the required column `currency_code` to the `transaction` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "account_balance" DROP CONSTRAINT "account_balances_account_id_foreign";

-- DropForeignKey
ALTER TABLE "transaction" DROP CONSTRAINT "transactions_account_id_foreign";

-- AlterTable
ALTER TABLE "account" DROP COLUMN "iso_currency_code",
DROP COLUMN "plaid_subtype",
DROP COLUMN "plaid_type",
DROP COLUMN "unofficial_currency_code",
ADD COLUMN     "currency_code" VARCHAR(3) NOT NULL,
ADD COLUMN     "house_meta" JSONB,
ADD COLUMN     "vehicle_meta" JSONB;

-- AlterTable
ALTER TABLE "account_balance" DROP COLUMN "closing_balance",
DROP COLUMN "credit_amount",
DROP COLUMN "debit_amount",
DROP COLUMN "quantity",
ADD COLUMN     "balance" BIGINT NOT NULL,
ADD COLUMN     "inflows" BIGINT NOT NULL DEFAULT 0,
ADD COLUMN     "outflows" BIGINT NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "account_connection" DROP COLUMN "plaid_institution_id";

-- AlterTable
ALTER TABLE "transaction" DROP COLUMN "iso_currency_code",
DROP COLUMN "plaid_category_id",
DROP COLUMN "plaid_transaction_id",
DROP COLUMN "unofficial_currency_code",
ADD COLUMN     "currency_code" VARCHAR(3) NOT NULL,
ADD COLUMN     "plaidTransactionId" VARCHAR(255),
ADD COLUMN     "quantity" BIGINT;

-- AddForeignKey
ALTER TABLE "account_balance" ADD CONSTRAINT "account_balances_account_id_foreign" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaction" ADD CONSTRAINT "transactions_account_id_foreign" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE CASCADE ON UPDATE CASCADE;
