-- CreateEnum
CREATE TYPE "UserGoal" AS ENUM ('retire', 'debt', 'save', 'invest');

-- AlterTable
ALTER TABLE "user" ADD COLUMN     "goals" "UserGoal"[],
ADD COLUMN     "goals_description" TEXT,
ADD COLUMN     "risk_tolerance" SMALLINT;

