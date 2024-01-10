ALTER TABLE "user" ADD COLUMN     "trial_end" TIMESTAMPTZ(6) DEFAULT NOW() + interval '14 days';

-- Users that are already subscribed or on a Stripe-based trial don't need a trial_end
UPDATE "user" SET "trial_end" = NULL WHERE "stripe_price_id" IS NOT NULL;