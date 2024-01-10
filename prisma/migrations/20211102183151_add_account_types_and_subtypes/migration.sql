-- CreateEnum
CREATE TYPE "AccountClassification" AS ENUM ('asset', 'liability');

-- CreateTable
CREATE TABLE "account_type" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "classification" "AccountClassification" NOT NULL,
    "plaid_types" TEXT[],

    CONSTRAINT "account_type_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "account_subtype" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "account_type_id" INTEGER NOT NULL,
    "plaid_subtypes" TEXT[],

    CONSTRAINT "account_subtype_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "account" RENAME COLUMN "type" TO "plaid_type";
ALTER TABLE "account" RENAME COLUMN "subtype" TO "plaid_subtype";
ALTER TABLE "account"
  ALTER COLUMN "plaid_type" DROP NOT NULL,
  ADD COLUMN    "subtype_id" INTEGER,
  ADD COLUMN    "type_id" INTEGER;

-- Add default types
INSERT INTO "account_type" ("name", "classification", "plaid_types") VALUES ('Other Asset', 'asset', '{other}'), ('Other Liability', 'liability', '{}');

-- Set default `type_id`s
UPDATE "account" SET "type_id" = CASE WHEN "plaid_type" = 'LIABILITY' THEN 2 ELSE 1 END;

-- Make `account`.`type_id` NOT NULL
ALTER TABLE "account" ALTER COLUMN "type_id" SET NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "account_type_name_key" ON "account_type"("name");

-- CreateIndex
CREATE UNIQUE INDEX "account_subtype_name_key" ON "account_subtype"("name");

-- AddForeignKey
ALTER TABLE "account" ADD CONSTRAINT "account_type_id_fkey" FOREIGN KEY ("type_id") REFERENCES "account_type"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account" ADD CONSTRAINT "account_subtype_id_fkey" FOREIGN KEY ("subtype_id") REFERENCES "account_subtype"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_subtype" ADD CONSTRAINT "account_subtype_account_type_id_fkey" FOREIGN KEY ("account_type_id") REFERENCES "account_type"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- CreateIndex
CREATE INDEX "accounts_type_id_index" ON "account"("type_id");

-- CreateIndex
CREATE INDEX "accounts_subtype_id_index" ON "account"("subtype_id");