-- CreateEnum
CREATE TYPE "AccountCategory" AS ENUM ('cash', 'investment', 'crypto', 'property', 'vehicle', 'valuable', 'loan', 'mortgage', 'credit', 'other');

-- Add new column with temporary suffix
ALTER TABLE "account" ADD COLUMN "category_tmp" "AccountCategory" NOT NULL DEFAULT E'other';

-- Populate new column with enum values
UPDATE "account" SET "category_tmp" = "category"::"AccountCategory";

-- Drop old column
ALTER TABLE "account" DROP COLUMN "category";

-- Rename new column to take its place
ALTER TABLE "account" RENAME COLUMN "category_tmp" TO "category";