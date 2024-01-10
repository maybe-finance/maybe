/*
  Warnings:

  - A unique constraint covering the columns `[conversation_id,advisor_id]` on the table `conversation_advisor` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "conversation_advisor_conversation_id_advisor_id_key" ON "conversation_advisor"("conversation_id", "advisor_id");
