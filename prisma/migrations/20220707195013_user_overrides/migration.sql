-- AlterTable
ALTER TABLE "user" ADD COLUMN     "monthly_debt_user" DECIMAL(19,4),
ADD COLUMN     "monthly_expenses_user" DECIMAL(19,4),
ADD COLUMN     "monthly_income_user" DECIMAL(19,4);
