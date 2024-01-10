/*
  Warnings:

  - A unique constraint covering the columns `[finicity_username]` on the table `user` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "user" ADD COLUMN     "finicity_username" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "user_finicity_username_key" ON "user"("finicity_username");

-- Populate new field for users that already have a finicity_customer_id
UPDATE "user" SET "finicity_username" = LPAD("user"."id"::text, 6, '0') WHERE "finicity_customer_id" IS NOT NULL; 