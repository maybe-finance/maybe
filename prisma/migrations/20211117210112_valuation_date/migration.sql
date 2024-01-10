/*
  Warnings:

  - Added the required column `date` to the `valuation` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "valuation" ADD COLUMN     "date" DATE NOT NULL;
