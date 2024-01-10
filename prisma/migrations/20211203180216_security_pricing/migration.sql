-- AlterTable
ALTER TABLE "security" ADD COLUMN     "pricing_last_synced_at" TIMESTAMPTZ(6);

-- Enable timescale
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- CreateTable
CREATE TABLE "security_pricing" (
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "security_id" INTEGER NOT NULL,
    "date" DATE NOT NULL,
    "price_close" DECIMAL(18,10) NOT NULL,

    CONSTRAINT "security_pricing_pkey" PRIMARY KEY ("security_id","date")
);

-- AddForeignKey
ALTER TABLE "security_pricing" ADD CONSTRAINT "security_pricing_security_id_fkey" FOREIGN KEY ("security_id") REFERENCES "security"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Convert security_pricing to hypertable
SELECT create_hypertable('security_pricing', 'date', if_not_exists => true, migrate_data => true);