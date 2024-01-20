-- AlterTable
ALTER TABLE "transaction"
  RENAME COLUMN "category" TO "category_old";

DROP VIEW IF EXISTS transactions_enriched;

ALTER TABLE "transaction"
  ADD COLUMN "category" TEXT NOT NULL DEFAULT 'Other'::text;

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
