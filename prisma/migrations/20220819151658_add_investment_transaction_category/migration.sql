-- CreateEnum
CREATE TYPE "InvestmentTransactionCategory" AS ENUM ('buy', 'sell', 'dividend', 'transfer', 'tax', 'fee', 'cancel', 'other');

-- AlterTable
ALTER TABLE "investment_transaction" ADD COLUMN     "category" "InvestmentTransactionCategory" NOT NULL GENERATED ALWAYS AS (
  CASE
      WHEN "plaid_type" = 'buy' THEN 'buy'::"InvestmentTransactionCategory"
      WHEN "plaid_type" = 'sell' THEN 'sell'::"InvestmentTransactionCategory"
      WHEN "plaid_subtype" IN ('dividend', 'qualified dividend', 'non-qualified dividend') THEN 'dividend'::"InvestmentTransactionCategory"
      WHEN "plaid_subtype" IN ('non-resident tax', 'tax', 'tax withheld') THEN 'tax'::"InvestmentTransactionCategory"
      WHEN "plaid_type" = 'fee' OR "plaid_subtype" IN ('account fee', 'legal fee', 'management fee', 'margin expense', 'transfer fee', 'trust fee') THEN 'fee'::"InvestmentTransactionCategory"
      WHEN "plaid_type" = 'cash' THEN 'transfer'::"InvestmentTransactionCategory"
      WHEN "plaid_type" = 'cancel' THEN 'cancel'::"InvestmentTransactionCategory"

      WHEN "finicity_investment_transaction_type" IN ('purchased', 'purchaseToClose', 'purchaseToCover', 'dividendReinvest', 'reinvestOfIncome') THEN 'buy'::"InvestmentTransactionCategory"
      WHEN "finicity_investment_transaction_type" IN ('sold', 'soldToClose', 'soldToOpen') THEN 'sell'::"InvestmentTransactionCategory"
      WHEN "finicity_investment_transaction_type" = 'dividend' THEN 'dividend'::"InvestmentTransactionCategory"
      WHEN "finicity_investment_transaction_type" = 'tax' THEN 'tax'::"InvestmentTransactionCategory"
      WHEN "finicity_investment_transaction_type" = 'fee' THEN 'fee'::"InvestmentTransactionCategory"
      WHEN "finicity_investment_transaction_type" IN ('transfer', 'contribution', 'deposit', 'income', 'interest') THEN 'transfer'::"InvestmentTransactionCategory"
      WHEN "finicity_investment_transaction_type" = 'cancel' THEN 'cancel'::"InvestmentTransactionCategory"

      ELSE 'other'::"InvestmentTransactionCategory"
    END
) STORED;
