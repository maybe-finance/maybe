/*
  Warnings:

  - You are about to drop the column `effective_date` on the `transaction` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "transaction_account_id_effective_date_idx";

-- AlterTable
ALTER TABLE "transaction" DROP COLUMN "effective_date";

-- CreateIndex
CREATE INDEX "transaction_account_id_date_idx" ON "transaction"("account_id", "date");
