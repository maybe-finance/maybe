-- DropForeignKey
ALTER TABLE "plan_event" DROP CONSTRAINT "plan_event_end_milestone_id_fkey";

-- DropForeignKey
ALTER TABLE "plan_event" DROP CONSTRAINT "plan_event_start_milestone_id_fkey";

-- AddForeignKey
ALTER TABLE "plan_event" ADD CONSTRAINT "plan_event_start_milestone_id_fkey" FOREIGN KEY ("start_milestone_id") REFERENCES "plan_milestone"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plan_event" ADD CONSTRAINT "plan_event_end_milestone_id_fkey" FOREIGN KEY ("end_milestone_id") REFERENCES "plan_milestone"("id") ON DELETE CASCADE ON UPDATE CASCADE;
