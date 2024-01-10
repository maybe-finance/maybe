-- DropForeignKey
ALTER TABLE "account" DROP CONSTRAINT "accounts_account_connection_id_foreign";

-- DropForeignKey
ALTER TABLE "account_connection" DROP CONSTRAINT "account_connections_user_id_foreign";

-- AlterTable
ALTER TABLE "account" ADD COLUMN     "user_id" INTEGER,
ALTER COLUMN "account_connection_id" DROP NOT NULL;

-- CreateTable
CREATE TABLE "valuation" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "account_id" INTEGER NOT NULL,
    "source" TEXT NOT NULL,
    "amount" BIGINT NOT NULL,
    "currency_code" TEXT NOT NULL DEFAULT E'USD',

    CONSTRAINT "valuation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "valuation_account_id_idx" ON "valuation"("account_id");

-- RenameForeignKey
ALTER TABLE "account_balance" RENAME CONSTRAINT "account_balances_account_id_foreign" TO "account_balance_account_id_fkey";

-- RenameForeignKey
ALTER TABLE "transaction" RENAME CONSTRAINT "transactions_account_id_foreign" TO "transaction_account_id_fkey";

-- AddForeignKey
ALTER TABLE "account_connection" ADD CONSTRAINT "account_connection_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account" ADD CONSTRAINT "account_account_connection_id_fkey" FOREIGN KEY ("account_connection_id") REFERENCES "account_connection"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account" ADD CONSTRAINT "account_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "valuation" ADD CONSTRAINT "valuation_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- RenameIndex
ALTER INDEX "accounts_account_connection_id_index" RENAME TO "account_account_connection_id_idx";

-- RenameIndex
ALTER INDEX "accounts_subtype_id_index" RENAME TO "account_subtype_id_idx";

-- RenameIndex
ALTER INDEX "accounts_type_id_index" RENAME TO "account_type_id_idx";

-- RenameIndex
ALTER INDEX "account_balances_account_id_index" RENAME TO "account_balance_account_id_idx";

-- RenameIndex
ALTER INDEX "account_connections_user_id_index" RENAME TO "account_connection_user_id_idx";

-- RenameIndex
ALTER INDEX "transactions_account_id_index" RENAME TO "transaction_account_id_idx";

-- RenameIndex
ALTER INDEX "users_auth0_id_unique" RENAME TO "user_auth0_id_key";
