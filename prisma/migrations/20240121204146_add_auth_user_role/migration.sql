-- CreateEnum
CREATE TYPE "AuthUserRole" AS ENUM ('user', 'admin', 'ci');

-- AlterTable
ALTER TABLE "auth_user" ADD COLUMN     "role" "AuthUserRole" NOT NULL DEFAULT 'user';
