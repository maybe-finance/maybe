-- DropForeignKey
ALTER TABLE "signed_agreement" DROP CONSTRAINT "signed_agreement_agreement_id_fkey";

-- DropForeignKey
ALTER TABLE "signed_agreement" DROP CONSTRAINT "signed_agreement_user_id_fkey";

-- AddForeignKey
ALTER TABLE "signed_agreement" ADD CONSTRAINT "signed_agreement_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signed_agreement" ADD CONSTRAINT "signed_agreement_agreement_id_fkey" FOREIGN KEY ("agreement_id") REFERENCES "agreement"("id") ON DELETE CASCADE ON UPDATE CASCADE;
