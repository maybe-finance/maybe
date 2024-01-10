-- AlterTable
ALTER TABLE "user" ADD COLUMN     "stripe_cancel_at" TIMESTAMPTZ(6),
ADD COLUMN     "stripe_current_period_end" TIMESTAMPTZ(6),
ADD COLUMN     "stripe_customer_id" TEXT,
ADD COLUMN     "stripe_price_id" TEXT,
ADD COLUMN     "stripe_subscription_id" TEXT,
ADD COLUMN     "stripe_trial_end" TIMESTAMPTZ(6);

-- CreateIndex
CREATE UNIQUE INDEX "user_stripe_customer_id_key" ON "user"("stripe_customer_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_stripe_subscription_id_key" ON "user"("stripe_subscription_id");
