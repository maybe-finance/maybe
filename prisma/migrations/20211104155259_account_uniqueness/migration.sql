/*
  Warnings:

  - A unique constraint covering the columns `[account_connection_id,plaid_account_id]` on the table `account` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "account_account_connection_id_plaid_account_id_key" ON "account"("account_connection_id", "plaid_account_id");
