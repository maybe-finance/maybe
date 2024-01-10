BEGIN;

DROP INDEX "transaction_category_idx";

ALTER TABLE "transaction" 
DROP COLUMN "category",
DROP COLUMN "category_provider",
DROP COLUMN "category_user",
ADD COLUMN "category_user" TEXT,
ADD COLUMN "category" TEXT NOT NULL GENERATED ALWAYS AS (
  COALESCE(
    category_user,
    CASE
      WHEN plaid_personal_finance_category->>'primary' = 'INCOME' THEN 'Income'
      WHEN plaid_personal_finance_category->>'detailed' IN ('LOAN_PAYMENTS_MORTGAGE_PAYMENT', 'RENT_AND_UTILITIES_RENT') THEN 'Housing Payments'
      WHEN plaid_personal_finance_category->>'detailed' = 'LOAN_PAYMENTS_CAR_PAYMENT' THEN 'Vehicle Payments'
      WHEN plaid_personal_finance_category->>'primary' = 'LOAN_PAYMENTS' THEN 'Other Payments'
      WHEN plaid_personal_finance_category->>'primary' = 'HOME_IMPROVEMENT' THEN 'Home Improvement' 
      WHEN plaid_personal_finance_category->>'primary' = 'GENERAL_MERCHANDISE' THEN 'Shopping'
      WHEN 
        (plaid_personal_finance_category->>'primary' = 'RENT_AND_UTILITIES' AND 
        plaid_personal_finance_category->>'detailed' <> 'RENT_AND_UTILITIES_RENT') THEN 'Utilities'
      WHEN plaid_personal_finance_category->>'primary' IN ('FOOD_AND_DRINK') THEN 'Food and Drink'
      WHEN plaid_personal_finance_category->>'primary' = 'TRANSPORTATION' THEN 'Transportation'
      WHEN plaid_personal_finance_category->>'primary' IN ('TRAVEL') THEN 'Travel'
      WHEN (plaid_personal_finance_category->>'primary' IN ('PERSONAL_CARE', 'MEDICAL') AND 
        plaid_personal_finance_category->>'detailed' <> 'MEDICAL_VETERINARY_SERVICES') THEN 'Health'
      WHEN finicity_categorization->>'category' IN ('Income', 'Paycheck') THEN 'Income'
      WHEN finicity_categorization->>'category' = 'Mortgage & Rent' THEN 'Housing Payments'
      WHEN finicity_categorization->>'category' IN ('Furnishings', 'Home Services', 'Home Improvement', 'Lawn and Garden') THEN 'Home Improvement'
      WHEN finicity_categorization->>'category' IN ('Streaming Services', 'Home Phone', 'Television', 'Bills & Utilities', 'Utilities', 'Internet / Broadband Charges', 'Mobile Phone') THEN 'Utilities'
      WHEN finicity_categorization->>'category' IN ('Fast Food', 'Food & Dining', 'Restaurants', 'Coffee Shops', 'Alcohol & Bars', 'Groceries') THEN 'Food and Drink'
      WHEN finicity_categorization->>'category' IN ('Auto & Transport', 'Gas & Fuel', 'Auto Insurance') THEN 'Transportation'
      WHEN finicity_categorization->>'category' IN ('Hotel', 'Travel', 'Rental Car & Taxi') THEN 'Travel'
      WHEN finicity_categorization->>'category' IN ('Health Insurance', 'Doctor', 'Pharmacy', 'Eyecare', 'Health & Fitness', 'Personal Care') THEN 'Health'
      ELSE 'Other'
    END
  )
) STORED;

-- DropEnum
DROP TYPE "TransactionCategory";

COMMIT;
