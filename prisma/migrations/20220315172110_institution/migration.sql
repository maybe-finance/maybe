-- CreateEnum
CREATE TYPE "Provider" AS ENUM ('PLAID', 'FINICITY');

-- CreateTable
CREATE TABLE "institution" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "provider" "Provider" NOT NULL,
    "provider_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "logo" TEXT,
    "primary_color" TEXT,
    "data" JSONB NOT NULL,

    CONSTRAINT "institution_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "institution_provider_provider_id_key" ON "institution"("provider", "provider_id");
