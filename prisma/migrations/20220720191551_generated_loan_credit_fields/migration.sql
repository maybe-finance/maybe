ALTER TABLE "account" 
ADD COLUMN "credit" JSONB 
GENERATED ALWAYS AS (
    COALESCE(credit_provider, '{}'::JSONB) || COALESCE(credit_user, '{}'::JSONB)
) STORED;

ALTER TABLE "account" 
ADD COLUMN "loan" JSONB 
GENERATED ALWAYS AS (
    COALESCE(loan_provider, '{}'::JSONB) || COALESCE(loan_user, '{}'::JSONB)
) STORED;

ALTER TABLE "account"
ALTER COLUMN "credit" SET NOT NULL,
ALTER COLUMN "loan" SET NOT NULL;