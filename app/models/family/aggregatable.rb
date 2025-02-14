module Family::Aggregatable
  extend ActiveSupport::Concern

  def income_categories_with_totals(date: Date.current)
    categories_with_stats(classification: "income", date: date)
  end

  def expense_categories_with_totals(date: Date.current)
    categories_with_stats(classification: "expense", date: date)
  end

  def category_stats
    CategoryStats.new(self)
  end

  def budgeting_stats
    BudgetingStats.new(self)
  end

  def account_stats
    AccountStats.new(self)
  end

  private
    CategoriesWithTotals = Struct.new(:total_money, :category_totals, keyword_init: true)
    CategoryWithStats = Struct.new(:category, :amount_money, :percentage, keyword_init: true)

    def categories_with_stats(classification:, date: Date.current)
      totals = category_stats.month_category_totals(date: date)

      classified_totals = totals.category_totals.select { |t| t.classification == classification }

      if classification == "income"
        total = totals.total_income
        categories_scope = categories.incomes
      else
        total = totals.total_expense
        categories_scope = categories.expenses
      end

      categories_with_uncategorized = categories_scope + [ categories_scope.uncategorized ]

      CategoriesWithTotals.new(
        total_money: Money.new(total, currency),
        category_totals: categories_with_uncategorized.map do |category|
          ct = classified_totals.find { |ct| ct.category_id == category&.id }

          CategoryWithStats.new(
            category: category,
            amount_money: Money.new(ct&.amount || 0, currency),
            percentage: ct&.percentage || 0
          )
        end
      )
    end
end
