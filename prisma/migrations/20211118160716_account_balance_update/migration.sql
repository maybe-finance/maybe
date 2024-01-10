/*
  Warnings:

  - You are about to drop the column `snapshot_date` on the `account_balance` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[account_id,date]` on the table `account_balance` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `date` to the `account_balance` table without a default value. This is not possible if the table is not empty.

*/
-- DropIndex
DROP INDEX "account_balance_account_id_idx";

-- DropIndex
DROP INDEX "account_balance_snapshot_date_account_id_key";

-- AlterTable
ALTER TABLE "account_balance"
ALTER COLUMN "inflows" DROP NOT NULL,
ALTER COLUMN "outflows" DROP NOT NULL;

ALTER TABLE "account_balance" RENAME COLUMN "snapshot_date" TO "date";

-- CreateIndex
CREATE UNIQUE INDEX "account_balance_account_id_date_key" ON "account_balance"("account_id", "date");
