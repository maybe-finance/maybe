-- AlterTable
ALTER TABLE "conversation" ADD COLUMN     "account_id" INTEGER,
ADD COLUMN     "plan_id" INTEGER;

-- AddForeignKey
ALTER TABLE "conversation" ADD CONSTRAINT "conversation_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation" ADD CONSTRAINT "conversation_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "plan"("id") ON DELETE SET NULL ON UPDATE CASCADE;
