/*
  Warnings:

  - A unique constraint covering the columns `[account_connection_id,teller_account_id]` on the table `account` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[teller_transaction_id]` on the table `transaction` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[teller_user_id]` on the table `user` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterEnum
ALTER TYPE "AccountConnectionType" ADD VALUE 'teller';

-- AlterTable
ALTER TABLE "account" ADD COLUMN     "teller_account_id" TEXT,
ADD COLUMN     "teller_type" TEXT;

-- AlterTable
ALTER TABLE "account_connection" ADD COLUMN     "teller_access_token" TEXT,
ADD COLUMN     "teller_account_id" TEXT,
ADD COLUMN     "teller_error" JSONB,
ADD COLUMN     "teller_institution_id" TEXT;

-- AlterTable
ALTER TABLE "transaction" ADD COLUMN     "teller_category" TEXT,
ADD COLUMN     "teller_transaction_id" TEXT,
ADD COLUMN     "teller_type" TEXT;

-- AlterTable
ALTER TABLE "user" ADD COLUMN     "teller_user_id" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "account_account_connection_id_teller_account_id_key" ON "account"("account_connection_id", "teller_account_id");

-- CreateIndex
CREATE UNIQUE INDEX "transaction_teller_transaction_id_key" ON "transaction"("teller_transaction_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_teller_user_id_key" ON "user"("teller_user_id");
