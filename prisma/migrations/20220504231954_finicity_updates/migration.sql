/*
  Warnings:

  - You are about to drop the column `finicity_holding_id` on the `holding` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[finicity_position_id]` on the table `holding` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[finicity_security_id,finicity_security_id_type]` on the table `security` will be added. If there are existing duplicate values, this will fail.

*/
-- DropIndex
DROP INDEX "holding_finicity_holding_id_key";

-- AlterTable
ALTER TABLE "holding" RENAME COLUMN "finicity_holding_id" TO "finicity_position_id";

-- CreateIndex
CREATE UNIQUE INDEX "holding_finicity_position_id_key" ON "holding"("finicity_position_id");

-- AlterTable
ALTER TABLE "security" ADD COLUMN     "finicity_security_id" TEXT,
ADD COLUMN     "finicity_security_id_type" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "security_finicity_security_id_finicity_security_id_type_key" ON "security"("finicity_security_id", "finicity_security_id_type");
