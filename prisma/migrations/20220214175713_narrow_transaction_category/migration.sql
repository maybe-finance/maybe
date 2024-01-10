/*
  Warnings:

  - The `category` column on the `transaction` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- CreateEnum
CREATE TYPE "TransactionCategory" AS ENUM ('INCOME', 'EXPENSE', 'TRANSFER', 'PAYMENT');

-- AlterTable
ALTER TABLE "transaction" DROP COLUMN "category",
ADD COLUMN     "category" "TransactionCategory";
