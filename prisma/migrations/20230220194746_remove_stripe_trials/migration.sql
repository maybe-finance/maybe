-- AlterTable
ALTER TABLE "user" DROP COLUMN "stripe_trial_end",
DROP COLUMN "stripe_trial_reminder_sent",
ADD COLUMN     "trial_reminder_sent" TIMESTAMPTZ(6),
ALTER COLUMN "trial_end" SET DEFAULT NOW() + interval '14 days';
