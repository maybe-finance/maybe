-- AlterTable
ALTER TABLE "user" ADD COLUMN     "member_id" TEXT NOT NULL DEFAULT gen_random_uuid();

-- CreateIndex
CREATE UNIQUE INDEX "user_member_id_key" ON "user"("member_id");
