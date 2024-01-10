-- AlterTable
ALTER TABLE "account" ADD COLUMN     "credit_provider" JSONB,
ADD COLUMN     "credit_user" JSONB,
ADD COLUMN     "loan_provider" JSONB,
ADD COLUMN     "loan_user" JSONB;
