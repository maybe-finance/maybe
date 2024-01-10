/*
  Warnings:

  - Made the column `user_id` on table `conversation` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "conversation" DROP CONSTRAINT "conversation_user_id_fkey";

-- AlterTable
ALTER TABLE "conversation" ALTER COLUMN "user_id" SET NOT NULL;

-- AddForeignKey
ALTER TABLE "conversation" ADD CONSTRAINT "conversation_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;
