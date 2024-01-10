-- AlterTable
ALTER TABLE "plan_event" ADD COLUMN "category" TEXT;

-- AlterTable
ALTER TABLE "plan_milestone" ADD COLUMN "category" TEXT NOT NULL DEFAULT 'retirement';
