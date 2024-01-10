-- CreateEnum
CREATE TYPE "Household" AS ENUM ('single', 'singleWithDependents', 'dual', 'dualWithDependents', 'retired');

-- CreateEnum
CREATE TYPE "MaybeGoal" AS ENUM ('aggregate', 'advice', 'plan');

-- AlterTable
ALTER TABLE "user" ADD COLUMN     "household" "Household",
ADD COLUMN     "maybe_goals" "MaybeGoal"[],
ADD COLUMN     "maybe_goals_description" TEXT;