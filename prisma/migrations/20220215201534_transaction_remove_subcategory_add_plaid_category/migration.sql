/*
  Warnings:

  - You are about to drop the column `subcategory` on the `transaction` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "transaction" DROP COLUMN "subcategory",
ADD COLUMN     "plaid_category" TEXT[];
