-- CreateEnum
CREATE TYPE "SecurityProvider" AS ENUM ('polygon', 'other');

-- AlterTable
ALTER TABLE "security" ADD COLUMN     "provider_name" "SecurityProvider" DEFAULT 'other';
