-- CreateEnum
CREATE TYPE "TaxStatus" AS ENUM ('single', 'married_joint', 'married_separate', 'head_of_household', 'qualifying_widow');

-- AlterTable
ALTER TABLE "user" ADD COLUMN     "dependents" INTEGER,
ADD COLUMN     "gross_income" INTEGER,
ADD COLUMN     "income_type" TEXT,
ADD COLUMN     "tax_status" "TaxStatus";

-- CreateTable
CREATE TABLE "conversation_note" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "user_id" INTEGER NOT NULL,
    "conversation_id" INTEGER NOT NULL,
    "body" TEXT NOT NULL,

    CONSTRAINT "conversation_note_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "conversation_note_user_id_conversation_id_key" ON "conversation_note"("user_id", "conversation_id");

-- AddForeignKey
ALTER TABLE "conversation_note" ADD CONSTRAINT "conversation_note_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation_note" ADD CONSTRAINT "conversation_note_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;
