-- account
ALTER TABLE "account" RENAME COLUMN "category" TO "category_provider";
ALTER TABLE "account" ALTER COLUMN "category_provider" DROP NOT NULL;
ALTER TABLE "account" ADD COLUMN "category_user" "AccountCategory";
ALTER TABLE "account" ADD CONSTRAINT category_present CHECK (num_nonnulls(category_user, category_provider) > 0);
ALTER TABLE "account" ADD COLUMN "category" "AccountCategory" NOT NULL GENERATED ALWAYS AS (
  COALESCE(category_user, category_provider)
) STORED;

ALTER TABLE "account" RENAME COLUMN "subcategory" TO "subcategory_provider";
ALTER TABLE "account" RENAME COLUMN "subcategory_override" TO "subcategory_user";
ALTER TABLE "account" ADD COLUMN "subcategory" TEXT NOT NULL GENERATED ALWAYS AS (
  COALESCE(
    subcategory_user,
    CASE 
      WHEN "type" = 'plaid' THEN "plaid_subtype"
      WHEN "type" = 'property' THEN 'property'
      WHEN "type" = 'vehicle' THEN 'vehicle'
		  ELSE 'other'
	  END
  )
) STORED;

-- transaction
ALTER TABLE "transaction" RENAME COLUMN "category" TO "category_provider";
ALTER TABLE "transaction" ADD COLUMN "category_user" "TransactionCategory";
ALTER TABLE "transaction" ADD COLUMN "category" "TransactionCategory" GENERATED ALWAYS AS (
  COALESCE(category_user, category_provider)
) STORED;
