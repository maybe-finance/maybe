-- AlterTable
ALTER TABLE "user" ADD COLUMN     "crisp_session_token" TEXT NOT NULL DEFAULT gen_random_uuid();
