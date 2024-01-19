ALTER TABLE
  "investment_transaction" DROP COLUMN "category";

ALTER TABLE
  "investment_transaction"
ADD
  COLUMN "category" "InvestmentTransactionCategory" DEFAULT 'other' :: "InvestmentTransactionCategory" NOT NULL;
