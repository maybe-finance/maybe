-- AlterEnum
ALTER TYPE "AccountProvider" ADD VALUE 'teller';

-- AlterTable
ALTER TABLE "account" ADD COLUMN     "teller_subtype" TEXT;
