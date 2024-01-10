/*
  Warnings:

  - A unique constraint covering the columns `[snapshot_date,account_id]` on the table `account_balance` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "account_balance_snapshot_date_account_id_key" ON "account_balance"("snapshot_date", "account_id");
