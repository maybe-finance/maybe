-- AlterTable
ALTER TABLE "transaction" ADD COLUMN     "plaid_category_id" TEXT,
ADD COLUMN     "plaid_personal_finance_category" JSONB;
