/*
  Warnings:

  - The values [SYNCING] on the enum `AccountConnectionStatus` will be removed. If these variants are still used in the database, this will fail.

*/
-- CreateEnum
CREATE TYPE "AccountSyncStatus" AS ENUM ('IDLE', 'PENDING', 'SYNCING');

-- AlterEnum
BEGIN;
CREATE TYPE "AccountConnectionStatus_new" AS ENUM ('OK', 'ERROR', 'DISCONNECTED');
ALTER TABLE "account_connection" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "account_connection" ALTER COLUMN "status" TYPE "AccountConnectionStatus_new" USING ("status"::text::"AccountConnectionStatus_new");
ALTER TYPE "AccountConnectionStatus" RENAME TO "AccountConnectionStatus_old";
ALTER TYPE "AccountConnectionStatus_new" RENAME TO "AccountConnectionStatus";
DROP TYPE "AccountConnectionStatus_old";
ALTER TABLE "account_connection" ALTER COLUMN "status" SET DEFAULT 'OK';
COMMIT;

-- AlterTable
ALTER TABLE "account" ADD COLUMN     "sync_status" "AccountSyncStatus" NOT NULL DEFAULT E'IDLE';

-- AlterTable
ALTER TABLE "account_connection" ADD COLUMN     "sync_status" "AccountSyncStatus" NOT NULL DEFAULT E'IDLE';
