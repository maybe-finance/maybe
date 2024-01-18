/*
  Warnings:

  - You are about to drop the column `teller_account_id` on the `account_connection` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "account_connection" DROP COLUMN "teller_account_id",
ADD COLUMN     "teller_enrollment_id" TEXT;
