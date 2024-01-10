-- AlterTable
ALTER TABLE "user" ADD COLUMN     "ata_all" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "ata_closed" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "ata_expire" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "ata_review" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "ata_submitted" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "ata_update" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "convert_kit_id" INTEGER;
