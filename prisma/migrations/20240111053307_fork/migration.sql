-- DropIndex
DROP INDEX "account_balance_date_idx";

-- DropIndex
DROP INDEX "security_pricing_date_idx";

-- AlterTable
ALTER TABLE "account" ALTER COLUMN "category" DROP DEFAULT,
ALTER COLUMN "classification" DROP DEFAULT;

-- AlterTable
ALTER TABLE "investment_transaction" ALTER COLUMN "flow" DROP DEFAULT,
ALTER COLUMN "category" DROP DEFAULT;

-- AlterTable
ALTER TABLE "transaction" ALTER COLUMN "flow" DROP DEFAULT;

-- AlterTable
ALTER TABLE "user" ALTER COLUMN "trial_end" SET DEFAULT NOW() + interval '14 days';

-- CreateIndex
CREATE INDEX "account_balance_date_idx" ON "account_balance"("date");

-- CreateIndex
CREATE INDEX "security_pricing_date_idx" ON "security_pricing"("date");
