-- AlterTable
ALTER TABLE "account" DROP COLUMN "credit", DROP COLUMN "loan";

ALTER TABLE "account"
ADD COLUMN "credit" JSONB
GENERATED ALWAYS AS (
    CASE WHEN num_nonnulls(credit_provider, credit_user) = 0 THEN NULL ELSE COALESCE(credit_provider, '{}'::JSONB) || COALESCE(credit_user, '{}'::JSONB) END
) STORED;

ALTER TABLE "account"
ADD COLUMN "loan" JSONB
GENERATED ALWAYS AS (
    CASE WHEN num_nonnulls(loan_provider, loan_user) = 0 THEN NULL ELSE COALESCE(loan_provider, '{}'::JSONB) || COALESCE(loan_user, '{}'::JSONB) END
) STORED;
