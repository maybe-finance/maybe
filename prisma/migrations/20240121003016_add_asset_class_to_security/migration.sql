-- CreateEnum
CREATE TYPE "AssetClass" AS ENUM ('cash', 'crypto', 'fixed_income', 'stocks', 'other');

-- AlterTable
ALTER TABLE "security"
  ADD COLUMN "asset_class" "AssetClass" NOT NULL DEFAULT 'other';
