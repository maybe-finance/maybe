/*
  Warnings:

  - You are about to drop the column `advisor_notes` on the `user` table. All the data in the column will be lost.
  - You are about to drop the column `ata_all` on the `user` table. All the data in the column will be lost.
  - You are about to drop the column `ata_closed` on the `user` table. All the data in the column will be lost.
  - You are about to drop the column `ata_expire` on the `user` table. All the data in the column will be lost.
  - You are about to drop the column `ata_review` on the `user` table. All the data in the column will be lost.
  - You are about to drop the column `ata_submitted` on the `user` table. All the data in the column will be lost.
  - You are about to drop the column `ata_update` on the `user` table. All the data in the column will be lost.
  - You are about to drop the column `goals` on the `user` table. All the data in the column will be lost.
  - You are about to drop the column `risk_answers` on the `user` table. All the data in the column will be lost.
  - You are about to drop the column `user_notes` on the `user` table. All the data in the column will be lost.
  - You are about to drop the `advisor` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `conversation` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `conversation_advisor` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `conversation_note` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `message` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "advisor" DROP CONSTRAINT "advisor_user_id_fkey";

-- DropForeignKey
ALTER TABLE "conversation" DROP CONSTRAINT "conversation_account_id_fkey";

-- DropForeignKey
ALTER TABLE "conversation" DROP CONSTRAINT "conversation_plan_id_fkey";

-- DropForeignKey
ALTER TABLE "conversation" DROP CONSTRAINT "conversation_user_id_fkey";

-- DropForeignKey
ALTER TABLE "conversation_advisor" DROP CONSTRAINT "conversation_advisor_advisor_id_fkey";

-- DropForeignKey
ALTER TABLE "conversation_advisor" DROP CONSTRAINT "conversation_advisor_conversation_id_fkey";

-- DropForeignKey
ALTER TABLE "conversation_note" DROP CONSTRAINT "conversation_note_conversation_id_fkey";

-- DropForeignKey
ALTER TABLE "conversation_note" DROP CONSTRAINT "conversation_note_user_id_fkey";

-- DropForeignKey
ALTER TABLE "message" DROP CONSTRAINT "message_conversation_id_fkey";

-- DropForeignKey
ALTER TABLE "message" DROP CONSTRAINT "message_user_id_fkey";

-- DropIndex
DROP INDEX "account_balance_date_idx";

-- DropIndex
DROP INDEX "security_pricing_date_idx";

-- AlterTable
ALTER TABLE "user" DROP COLUMN "advisor_notes",
DROP COLUMN "ata_all",
DROP COLUMN "ata_closed",
DROP COLUMN "ata_expire",
DROP COLUMN "ata_review",
DROP COLUMN "ata_submitted",
DROP COLUMN "ata_update",
DROP COLUMN "goals",
DROP COLUMN "risk_answers",
DROP COLUMN "user_notes";

-- DropTable
DROP TABLE "advisor";

-- DropTable
DROP TABLE "conversation";

-- DropTable
DROP TABLE "conversation_advisor";

-- DropTable
DROP TABLE "conversation_note";

-- DropTable
DROP TABLE "message";

-- DropEnum
DROP TYPE "ConversationStatus";

-- DropEnum
DROP TYPE "MessageType";

-- CreateIndex
CREATE INDEX "account_balance_date_idx" ON "account_balance"("date");

-- CreateIndex
CREATE INDEX "security_pricing_date_idx" ON "security_pricing"("date");
