
-- CreateEnum
CREATE TYPE "AgreementType" AS ENUM ('fee', 'form_adv', 'form_crs', 'privacy_policy');

-- AlterTable
ALTER TABLE "user" DROP COLUMN "agreements_revision";

-- CreateTable
CREATE TABLE "agreement" (
    "id" SERIAL NOT NULL,
    "type" "AgreementType" NOT NULL,
    "revision" DATE NOT NULL,
    "src" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "agreement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "signed_agreement" (
    "signed_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "user_id" INTEGER NOT NULL,
    "agreement_id" INTEGER NOT NULL,
    "src" TEXT,

    CONSTRAINT "signed_agreement_pkey" PRIMARY KEY ("user_id","agreement_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "agreement_src_key" ON "agreement"("src");

-- CreateIndex
CREATE UNIQUE INDEX "agreement_type_revision_key" ON "agreement"("type", "revision");

-- AddForeignKey
ALTER TABLE "signed_agreement" ADD CONSTRAINT "signed_agreement_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signed_agreement" ADD CONSTRAINT "signed_agreement_agreement_id_fkey" FOREIGN KEY ("agreement_id") REFERENCES "agreement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
