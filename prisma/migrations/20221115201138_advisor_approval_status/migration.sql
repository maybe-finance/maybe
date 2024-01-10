-- CreateEnum
CREATE TYPE "ApprovalStatus" AS ENUM ('pending', 'approved', 'rejected');

-- AlterTable
ALTER TABLE "advisor" ADD COLUMN "approval_status" "ApprovalStatus" NOT NULL DEFAULT 'pending';
