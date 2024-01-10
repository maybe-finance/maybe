BEGIN;

ALTER TABLE "account" RENAME COLUMN "category" TO "category_old";
ALTER TABLE "account" RENAME COLUMN "category_provider" TO "category_provider_old";
ALTER TABLE "account" RENAME COLUMN "category_user" TO "category_user_old";
ALTER TYPE "AccountCategory" RENAME TO "AccountCategory_old";

CREATE TYPE "AccountCategory" AS ENUM ('cash', 'investment', 'crypto', 'property', 'vehicle', 'valuable', 'loan', 'credit', 'other');
ALTER TABLE "account" ADD COLUMN "category_provider" "AccountCategory";
ALTER TABLE "account" ADD COLUMN "category_user" "AccountCategory";

UPDATE "account"
SET "category_provider" = CASE 
  WHEN "category_provider_old" = 'mortgage' THEN 'loan'
  ELSE "category_provider_old"::TEXT::"AccountCategory"
END;

UPDATE "account"
SET "category_user" = CASE 
  WHEN "category_user_old" = 'mortgage' THEN 'loan'
  ELSE "category_user_old"::TEXT::"AccountCategory"
END;

ALTER TABLE "account" ADD COLUMN "category" "AccountCategory" NOT NULL GENERATED ALWAYS AS (
  COALESCE(category_user, category_provider, 'other')
) STORED;

ALTER TABLE "account" DROP COLUMN "category_old";
ALTER TABLE "account" DROP COLUMN "category_provider_old";
ALTER TABLE "account" DROP COLUMN "category_user_old";
DROP TYPE "AccountCategory_old";

COMMIT;