-- DropIndex
DROP INDEX "transaction_category_idx";

-- AlterTable
ALTER TABLE "account" ALTER COLUMN "category_provider" DROP DEFAULT;

-- CreateIndex
CREATE INDEX "transaction_category_idx" ON "transaction"("category");
