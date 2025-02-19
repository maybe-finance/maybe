class IncomeStatement
  include Monetizable

  monetize :median_expense, :median_income

  attr_reader :family

  def initialize(family)
    @family = family
  end

  def totals(transactions_scope: nil)
    transactions_scope ||= family.transactions.active

    result = totals_query(transactions_scope: transactions_scope)

    total_income = result.select { |t| t.classification == "income" }.sum(&:total)
    total_expense = result.select { |t| t.classification == "expense" }.sum(&:total)

    ScopeTotals.new(
      transactions_count: transactions_scope.count,
      income_money: Money.new(total_income, family.currency),
      expense_money: Money.new(total_expense, family.currency),
      missing_exchange_rates?: result.any?(&:missing_exchange_rates?)
    )
  end

  def expense(period: Period.current_month)
    build_period_total(classification: "expense", period: period)
  end

  def income(period: Period.current_month)
    build_period_total(classification: "income", period: period)
  end

  def median_expense(interval: "month", category: nil)
    if category.present?
      category_stats(interval: interval).find { |stat| stat.classification == "expense" && stat.category_id == category.id }&.median || 0
    else
      family_stats(interval: interval).find { |stat| stat.classification == "expense" }&.median || 0
    end
  end

  def avg_expense(interval: "month", category: nil)
    if category.present?
      category_stats(interval: interval).find { |stat| stat.classification == "expense" && stat.category_id == category.id }&.avg || 0
    else
      family_stats(interval: interval).find { |stat| stat.classification == "expense" }&.avg || 0
    end
  end

  def median_income(interval: "month")
    family_stats(interval: interval).find { |stat| stat.classification == "income" }&.median || 0
  end

  private
    ScopeTotals = Data.define(:transactions_count, :income_money, :expense_money, :missing_exchange_rates?)
    PeriodTotal = Data.define(:classification, :total, :currency, :missing_exchange_rates?, :category_totals)
    CategoryTotal = Data.define(:category, :total, :currency, :weight)

    def categories
      @categories ||= family.categories.all.to_a
    end

    def build_period_total(classification:, period:)
      totals = totals_query(transactions_scope: family.transactions.active.in_period(period)).select { |t| t.classification == classification }
      classification_total = totals.sum(&:total)

      category_totals = totals.map do |ct|
        # If parent category is nil, it's a top-level category.  This means we need to
        # sum itself + SUM(children) to get the overall category total
        children_totals = if ct.parent_category_id.nil? && ct.category_id.present?
          totals.select { |t| t.parent_category_id == ct.category_id }.sum(&:total)
        else
          0
        end

        category_total = ct.total + children_totals

        weight = (category_total.zero? ? 0 : category_total.to_f / classification_total) * 100

        CategoryTotal.new(
          category: categories.find { |c| c.id == ct.category_id } || family.categories.uncategorized,
          total: category_total,
          currency: family.currency,
          weight: weight,
        )
      end

      PeriodTotal.new(
        classification: classification,
        total: category_totals.reject { |ct| ct.category.subcategory? }.sum(&:total),
        currency: family.currency,
        missing_exchange_rates?: totals.any?(&:missing_exchange_rates?),
        category_totals: category_totals
      )
    end

    def family_stats(interval: "month")
      FamilyStats.new(family, interval:).call
    end

    def category_stats(interval: "month")
      CategoryStats.new(family, interval:).call
    end

    def totals_query(transactions_scope:)
      Totals.new(family, transactions_scope: transactions_scope).call
    end

    def monetizable_currency
      family.currency
    end
end
