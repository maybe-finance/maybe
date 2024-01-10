/*
  Warnings:

  - You are about to drop the column `data` on the `institution` table. All the data in the column will be lost.
  - You are about to drop the column `provider` on the `institution` table. All the data in the column will be lost.
  - You are about to drop the column `provider_id` on the `institution` table. All the data in the column will be lost.

*/
-- CreateTable
CREATE TABLE "provider_institution" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "provider" "Provider" NOT NULL,
    "provider_id" TEXT NOT NULL,
    "institution_id" INTEGER,
    "rank" INTEGER NOT NULL DEFAULT 0,
    "name" TEXT NOT NULL,
    "url" TEXT,
    "logo" TEXT,
    "logo_url" TEXT,
    "primary_color" TEXT,
    "data" JSONB,

    CONSTRAINT "provider_institution_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "provider_institution_provider_provider_id_key" ON "provider_institution"("provider", "provider_id");

-- migrate institution data into provider_institution
INSERT INTO provider_institution (provider, provider_id, name, url, logo, logo_url, primary_color, data)
SELECT
  provider,
  provider_id,
  name,
  url,
  logo,
  logo_url,
  primary_color,
  data
FROM
  institution;

-- delete data from institution table
TRUNCATE TABLE institution RESTART IDENTITY;

-- AddForeignKey
ALTER TABLE "provider_institution" ADD CONSTRAINT "provider_institution_institution_id_fkey" FOREIGN KEY ("institution_id") REFERENCES "institution"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- DropIndex
DROP INDEX "institution_provider_provider_id_key";

-- AlterTable
ALTER TABLE "institution" DROP COLUMN "data",
DROP COLUMN "provider",
DROP COLUMN "provider_id";