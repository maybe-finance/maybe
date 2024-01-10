-- rename type -> flow
ALTER TYPE "TransactionType" RENAME TO "TransactionFlow";

ALTER TABLE "transaction" DROP COLUMN "type";
ALTER TABLE "transaction" ADD COLUMN "flow" "TransactionFlow" NOT NULL GENERATED ALWAYS AS (CASE WHEN amount < 0 THEN 'INFLOW'::"TransactionFlow" ELSE 'OUTFLOW'::"TransactionFlow" END) STORED;

ALTER TABLE "investment_transaction" DROP COLUMN "type";
ALTER TABLE "investment_transaction" ADD COLUMN "flow" "TransactionFlow" NOT NULL GENERATED ALWAYS AS (CASE WHEN amount < 0 THEN 'INFLOW'::"TransactionFlow" ELSE 'OUTFLOW'::"TransactionFlow" END) STORED;

-- create type enum (this is only used in queries for the time being)
CREATE TYPE "TransactionType" AS ENUM ('INCOME', 'EXPENSE', 'PAYMENT', 'TRANSFER');

-- add defaults for currency_code
ALTER TABLE "account" ALTER COLUMN "currency_code" SET DEFAULT E'USD';
ALTER TABLE "transaction" ALTER COLUMN "currency_code" SET DEFAULT E'USD';
