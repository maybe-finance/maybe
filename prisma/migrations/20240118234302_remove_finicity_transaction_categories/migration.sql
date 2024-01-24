-- AlterTable
ALTER TABLE "transaction"
    RENAME COLUMN "category" TO "category_old";
ALTER TABLE "transaction"
    RENAME COLUMN "category_user" TO "category_user_old";

DROP VIEW IF EXISTS transactions_enriched;

ALTER TABLE "transaction" ADD COLUMN "category_user" TEXT;

ALTER TABLE "transaction"
    ADD COLUMN "category" TEXT NOT NULL GENERATED ALWAYS AS (COALESCE(category_user,
CASE
    WHEN ((plaid_personal_finance_category ->> 'primary'::text) = 'INCOME'::text) THEN 'Income'::text
    WHEN ((plaid_personal_finance_category ->> 'detailed'::text) = ANY (ARRAY['LOAN_PAYMENTS_MORTGAGE_PAYMENT'::text, 'RENT_AND_UTILITIES_RENT'::text])) THEN 'Housing Payments'::text
    WHEN ((plaid_personal_finance_category ->> 'detailed'::text) = 'LOAN_PAYMENTS_CAR_PAYMENT'::text) THEN 'Vehicle Payments'::text
    WHEN ((plaid_personal_finance_category ->> 'primary'::text) = 'LOAN_PAYMENTS'::text) THEN 'Other Payments'::text
    WHEN ((plaid_personal_finance_category ->> 'primary'::text) = 'HOME_IMPROVEMENT'::text) THEN 'Home Improvement'::text
    WHEN ((plaid_personal_finance_category ->> 'primary'::text) = 'GENERAL_MERCHANDISE'::text) THEN 'Shopping'::text
    WHEN (((plaid_personal_finance_category ->> 'primary'::text) = 'RENT_AND_UTILITIES'::text) AND ((plaid_personal_finance_category ->> 'detailed'::text) <> 'RENT_AND_UTILITIES_RENT'::text)) THEN 'Utilities'::text
    WHEN ((plaid_personal_finance_category ->> 'primary'::text) = 'FOOD_AND_DRINK'::text) THEN 'Food and Drink'::text
    WHEN ((plaid_personal_finance_category ->> 'primary'::text) = 'TRANSPORTATION'::text) THEN 'Transportation'::text
    WHEN ((plaid_personal_finance_category ->> 'primary'::text) = 'TRAVEL'::text) THEN 'Travel'::text
    WHEN (((plaid_personal_finance_category ->> 'primary'::text) = ANY (ARRAY['PERSONAL_CARE'::text, 'MEDICAL'::text])) AND ((plaid_personal_finance_category ->> 'detailed'::text) <> 'MEDICAL_VETERINARY_SERVICES'::text)) THEN 'Health'::text
    WHEN (teller_category = 'income'::text) THEN 'Income'::text
    WHEN (teller_category = 'home'::text) THEN 'Home Improvement'::text
    WHEN (teller_category = ANY (ARRAY['phone'::text, 'utilities'::text])) THEN 'Utilities'::text
    WHEN (teller_category = ANY (ARRAY['dining'::text, 'bar'::text, 'groceries'::text])) THEN 'Food and Drink'::text
    WHEN (teller_category = ANY (ARRAY['clothing'::text, 'entertainment'::text, 'shopping'::text, 'electronics'::text, 'software'::text, 'sport'::text])) THEN 'Shopping'::text
    WHEN (teller_category = ANY (ARRAY['transportation'::text, 'fuel'::text])) THEN 'Transportation'::text
    WHEN (teller_category = ANY (ARRAY['accommodation'::text, 'transport'::text])) THEN 'Travel'::text
    WHEN (teller_category = 'health'::text) THEN 'Health'::text
    WHEN (teller_category = ANY (ARRAY['loan'::text, 'tax'::text, 'insurance'::text, 'office'::text])) THEN 'Other Payments'::text
    ELSE 'Other'::text
END)) STORED;

CREATE OR REPLACE VIEW transactions_enriched AS (
  SELECT
    t.id,
    t.created_at as "createdAt",
    t.updated_at as "updatedAt",
    t.name,
    t.account_id as "accountId",
    t.date,
    t.flow,
    COALESCE(
      t.type_user,
      CASE
        -- no matching transaction
        WHEN t.match_id IS NULL THEN (
          CASE
            t.flow
            WHEN 'INFLOW' THEN (
              CASE
                a.classification
                WHEN 'asset' THEN 'INCOME' :: "TransactionType"
                WHEN 'liability' THEN 'PAYMENT' :: "TransactionType"
              END
            )
            WHEN 'OUTFLOW' THEN 'EXPENSE' :: "TransactionType"
          END
        ) -- has matching transaction
        ELSE (
          CASE
            a.classification
            WHEN 'asset' THEN 'TRANSFER' :: "TransactionType"
            WHEN 'liability' THEN 'PAYMENT' :: "TransactionType"
          END
        )
      END
    ) AS "type",
    t.type_user as "typeUser",
    t.amount,
    t.currency_code as "currencyCode",
    t.pending,
    t.merchant_name as "merchantName",
    t.category,
    t.category_user as "categoryUser",
    t.excluded,
    t.match_id as "matchId",
    COALESCE(ac.user_id, a.user_id) as "userId",
    a.classification as "accountClassification",
    a.type as "accountType"
  FROM
    transaction t
    inner join account a on a.id = t.account_id
    left join account_connection ac on a.account_connection_id = ac.id
);

ALTER TABLE "transaction" DROP COLUMN "category_old";
ALTER TABLE "transaction" DROP COLUMN "category_user_old";
