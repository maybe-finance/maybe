/*
  Warnings:

  - The primary key for the `account_balance` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `id` on the `account_balance` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "account_balance_account_id_date_key";

-- AlterTable
ALTER TABLE "account_balance" DROP CONSTRAINT "account_balance_pkey",
DROP COLUMN "id",
ADD CONSTRAINT "account_balance_pkey" PRIMARY KEY ("account_id", "date");

-- Convert account_balance to hypertable
SELECT create_hypertable('account_balance', 'date', if_not_exists => true, migrate_data => true);