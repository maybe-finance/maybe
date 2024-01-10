-- AlterTable
ALTER TABLE "security" ADD COLUMN     "finicity_asset_class" TEXT,
ADD COLUMN     "finicity_fi_asset_class" TEXT,
ADD COLUMN     "finicity_type" TEXT,
ADD COLUMN     "plaid_is_cash_equivalent" BOOLEAN;
