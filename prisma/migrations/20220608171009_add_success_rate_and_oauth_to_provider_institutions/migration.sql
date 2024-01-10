-- AlterTable
ALTER TABLE "provider_institution" ADD COLUMN     "oauth" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "success_rate" DECIMAL(65,30);
