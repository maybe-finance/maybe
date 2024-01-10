/*
  Warnings:

  - You are about to drop the column `success_rate` on the `provider_institution` table. All the data in the column will be lost.
  - You are about to drop the column `success_rate_updated` on the `provider_institution` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "provider_institution" DROP COLUMN "success_rate",
DROP COLUMN "success_rate_updated";
