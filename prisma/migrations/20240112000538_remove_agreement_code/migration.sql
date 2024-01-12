/*
  Warnings:

  - You are about to drop the `agreement` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `signed_agreement` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "signed_agreement" DROP CONSTRAINT "signed_agreement_agreement_id_fkey";

-- DropForeignKey
ALTER TABLE "signed_agreement" DROP CONSTRAINT "signed_agreement_user_id_fkey";

-- DropTable
DROP TABLE "agreement";

-- DropTable
DROP TABLE "signed_agreement";

-- DropEnum
DROP TYPE "AgreementType";
