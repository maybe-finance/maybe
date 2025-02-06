class BudgetingStats
  attr_reader :family

  def initialize(family)
    @family = family
  end

  def avg_monthly_income
    income_expense_totals_query(Account::Entry.incomes)
  end

  def avg_monthly_expenses
    income_expense_totals_query(Account::Entry.expenses)
  end

  private
    def income_expense_totals_query(type_scope)
      monthly_totals = family.entries
                        .merge(type_scope)
                        .select("SUM(account_entries.amount) as total")
                        .group(Arel.sql("date_trunc('month', account_entries.date)"))

      result = Family.select("AVG(mt.total)")
                     .from(monthly_totals, :mt)
                     .pick("AVG(mt.total)")

      result&.round(2)
    end
end
