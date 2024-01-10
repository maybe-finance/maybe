/*
  Warnings:

  - You are about to drop the column `plaidTransactionId` on the `transaction` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[plaid_item_id]` on the table `account_connection` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[plaid_transaction_id]` on the table `transaction` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "AccountConnectionStatus" AS ENUM ('OK', 'ERROR');

-- AlterTable
ALTER TABLE "account_connection" ADD COLUMN     "plaid_consent_expiration" TIMESTAMP(3),
ADD COLUMN     "plaid_error" JSONB,
ADD COLUMN     "status" "AccountConnectionStatus" NOT NULL DEFAULT E'OK';

-- AlterTable
ALTER TABLE "transaction" RENAME COLUMN "plaidTransactionId" TO "plaid_transaction_id";

-- CreateIndex
CREATE UNIQUE INDEX "account_connection_plaid_item_id_key" ON "account_connection"("plaid_item_id");

-- CreateIndex
CREATE UNIQUE INDEX "transaction_plaid_transaction_id_key" ON "transaction"("plaid_transaction_id");
