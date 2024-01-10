/*
  Warnings:

  - You are about to drop the column `price` on the `holding` table. All the data in the column will be lost.
  - You are about to drop the column `price_as_of` on the `holding` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "holding" DROP COLUMN "price",
DROP COLUMN "price_as_of";
