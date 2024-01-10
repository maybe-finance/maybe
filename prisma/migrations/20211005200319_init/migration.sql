-- CreateTable
CREATE TABLE "account_balance" (
    "id" SERIAL NOT NULL,
    "snapshot_date" DATE NOT NULL,
    "closing_balance" BIGINT NOT NULL,
    "debit_amount" BIGINT NOT NULL,
    "credit_amount" BIGINT NOT NULL,
    "quantity" BIGINT,
    "account_id" INTEGER NOT NULL,

    CONSTRAINT "account_balance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "account_connection" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "type" VARCHAR(255) NOT NULL,
    "plaid_item_id" VARCHAR(255),
    "plaid_access_token" VARCHAR(255),
    "plaid_institution_id" VARCHAR(255),
    "user_id" INTEGER NOT NULL,

    CONSTRAINT "account_connection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "account" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "plaid_account_id" VARCHAR(255),
    "is_active" BOOLEAN NOT NULL,
    "plaid_type" VARCHAR(255),
    "plaid_subtype" VARCHAR(255),
    "type" VARCHAR(255) NOT NULL,
    "subtype" VARCHAR(255),
    "current_balance" BIGINT,
    "available_balance" BIGINT,
    "iso_currency_code" VARCHAR(3) NOT NULL,
    "unofficial_currency_code" VARCHAR(255),
    "account_connection_id" INTEGER NOT NULL,

    CONSTRAINT "account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transaction" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "amount" BIGINT NOT NULL,
    "type" VARCHAR(255) NOT NULL,
    "pending" BOOLEAN NOT NULL,
    "posted_date" TIMESTAMPTZ(6) NOT NULL,
    "effective_date" DATE NOT NULL,
    "plaid_transaction_id" VARCHAR(255),
    "plaid_category_id" VARCHAR(255),
    "category" VARCHAR(255) NOT NULL,
    "subcategory" VARCHAR(255),
    "iso_currency_code" VARCHAR(3) NOT NULL,
    "unofficial_currency_code" VARCHAR(255),
    "account_id" INTEGER NOT NULL,

    CONSTRAINT "transaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "auth0_id" VARCHAR(255) NOT NULL,
    "iso_currency_code" VARCHAR(3) NOT NULL DEFAULT E'USD',

    CONSTRAINT "user_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "account_balances_account_id_index" ON "account_balance"("account_id");

-- CreateIndex
CREATE INDEX "account_connections_user_id_index" ON "account_connection"("user_id");

-- CreateIndex
CREATE INDEX "accounts_account_connection_id_index" ON "account"("account_connection_id");

-- CreateIndex
CREATE INDEX "transactions_account_id_index" ON "transaction"("account_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_auth0_id_unique" ON "user"("auth0_id");

-- AddForeignKey
ALTER TABLE "account_balance" ADD CONSTRAINT "account_balances_account_id_foreign" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "account_connection" ADD CONSTRAINT "account_connections_user_id_foreign" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "account" ADD CONSTRAINT "accounts_account_connection_id_foreign" FOREIGN KEY ("account_connection_id") REFERENCES "account_connection"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "transaction" ADD CONSTRAINT "transactions_account_id_foreign" FOREIGN KEY ("account_id") REFERENCES "account"("id") ON DELETE CASCADE ON UPDATE NO ACTION;
