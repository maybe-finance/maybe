-- AlterTable
ALTER TABLE "account" ALTER COLUMN "is_active" SET DEFAULT true;

-- AlterTable
ALTER TABLE "account_balance" ALTER COLUMN "debit_amount" SET DEFAULT 0,
ALTER COLUMN "credit_amount" SET DEFAULT 0;

-- AlterTable
ALTER TABLE "transaction" ALTER COLUMN "pending" SET DEFAULT false,
ALTER COLUMN "category" SET DEFAULT E'Default';
