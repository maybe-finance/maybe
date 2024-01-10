-- DropIndex
DROP INDEX "investment_transaction_account_id_idx";

-- DropIndex
DROP INDEX "transaction_account_id_idx";

-- DropIndex
DROP INDEX "valuation_account_id_idx";

-- CreateIndex
CREATE INDEX "investment_transaction_account_id_date_idx" ON "investment_transaction"("account_id", "date");

-- CreateIndex
CREATE INDEX "transaction_account_id_effective_date_idx" ON "transaction"("account_id", "effective_date");

-- CreateIndex
CREATE INDEX "valuation_account_id_date_idx" ON "valuation"("account_id", "date");
