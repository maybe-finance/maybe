/*
  Warnings:

  - You are about to drop the column `auth0_id` on the `user` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "user_auth0_id_key";

-- AlterTable
ALTER TABLE "user" DROP COLUMN "auth0_id";
