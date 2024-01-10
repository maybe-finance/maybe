/*
  Warnings:

  - You are about to drop the column `quantity` on the `transaction` table. All the data in the column will be lost.
  - Changed the type of `type` on the `transaction` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "TransactionType" AS ENUM ('INFLOW', 'OUTFLOW');

-- Convert transaction amount to a signed value
UPDATE "transaction"
SET amount = -1 * amount
WHERE type = 'INFLOW';

-- AlterTable
ALTER TABLE "transaction" DROP COLUMN "quantity",
DROP COLUMN "type",
ADD COLUMN  "type" "TransactionType" GENERATED ALWAYS AS (CASE WHEN amount < 0 THEN 'INFLOW'::"TransactionType" ELSE 'OUTFLOW'::"TransactionType" END) STORED;

-- CreateTable
CREATE TABLE "holding" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "account_id" INTEGER NOT NULL,
    "security_id" INTEGER NOT NULL,
    "value" BIGINT NOT NULL,
    "quantity" DECIMAL(36,18) NOT NULL,
    "cost_basis" BIGINT,
    "price" BIGINT NOT NULL,
    "price_as_of" DATE,
    "currency_code" TEXT NOT NULL DEFAULT E'USD',
    "plaid_holding_id" TEXT,

    CONSTRAINT "holding_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "investment_transaction" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "account_id" INTEGER NOT NULL,
    "security_id" INTEGER,
    "date" DATE NOT NULL,
    "name" TEXT NOT NULL,
    "amount" BIGINT NOT NULL,
    "type" "TransactionType" GENERATED ALWAYS AS (CASE WHEN amount < 0 THEN 'INFLOW'::"TransactionType" ELSE 'OUTFLOW'::"TransactionType" END) STORED,
    "quantity" DECIMAL(36,18) NOT NULL,
    "price" BIGINT NOT NULL,
    "currency_code" TEXT NOT NULL DEFAULT E'USD',
    "plaid_investment_transaction_id" TEXT,
    "plaid_type" TEXT,
    "plaid_subtype" TEXT,

    CONSTRAINT "investment_transaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "security" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "name" TEXT,
    "symbol" TEXT,
    "cusip" TEXT,
    "isin" TEXT,
    "currency_code" TEXT NOT NULL DEFAULT E'USD',
    "plaid_security_id" TEXT,
    "plaid_type" TEXT,

    CONSTRAINT "security_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "holding_plaid_holding_id_key" ON "holding"("plaid_holding_id");

-- CreateIndex
CREATE UNIQUE INDEX "holding_account_id_security_id_key" ON "holding"("account_id", "security_id");

-- CreateIndex
CREATE UNIQUE INDEX "investment_transaction_plaid_investment_transaction_id_key" ON "investment_transaction"("plaid_investment_transaction_id");

-- CreateIndex
CREATE INDEX "investment_transaction_account_id_idx" ON "investment_transaction"("account_id");

-- CreateIndex
CREATE UNIQUE INDEX "security_plaid_security_id_key" ON "security"("plaid_security_id");

-- AddForeignKey
ALTER TABLE "holding" ADD CONSTRAINT "holding_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "holding" ADD CONSTRAINT "holding_security_id_fkey" FOREIGN KEY ("security_id") REFERENCES "security"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "investment_transaction" ADD CONSTRAINT "investment_transaction_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "investment_transaction" ADD CONSTRAINT "investment_transaction_security_id_fkey" FOREIGN KEY ("security_id") REFERENCES "security"("id") ON DELETE CASCADE ON UPDATE CASCADE;
