class IncomeStatement
  include Monetizable
  include Promptable

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

  def expense_totals(period: Period.current_month)
    build_period_total(classification: "expense", period: period)
  end

  def income_totals(period: Period.current_month)
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

  # AI-friendly representation of income statement data
  def to_ai_readable_hash(period: Period.current_month)
    expense_data = expense_totals(period: period)
    income_data = income_totals(period: period)

    {
      period: {
        start_date: period.start_date.to_s,
        end_date: period.end_date.to_s
      },
      total_income: format_currency(income_data.total),
      total_expenses: format_currency(expense_data.total),
      net_income: format_currency(income_data.total - expense_data.total),
      savings_rate: calculate_savings_rate(income_data.total, expense_data.total),
      currency: family.currency
    }
  end

  # Detailed summary of income statement for AI
  def detailed_summary(period: Period.current_month)
    expense_data = expense_totals(period: period)
    income_data = income_totals(period: period)

    {
      period_info: {
        name: period_name(period),
        start_date: format_date(period.start_date),
        end_date: format_date(period.end_date),
        days: (period.end_date - period.start_date).to_i + 1
      },
      income: {
        total: format_currency(income_data.total),
        categories: income_data.category_totals
          .reject { |ct| ct.category.subcategory? }
          .sort_by { |ct| -ct.total }
          .map do |ct|
            {
              name: ct.category.name,
              amount: format_currency(ct.total),
              percentage: format_percentage(ct.weight)
            }
          end
      },
      expenses: {
        total: format_currency(expense_data.total),
        categories: expense_data.category_totals
          .reject { |ct| ct.category.subcategory? }
          .sort_by { |ct| -ct.total }
          .map do |ct|
            {
              name: ct.category.name,
              amount: format_currency(ct.total),
              percentage: format_percentage(ct.weight)
            }
          end
      },
      savings: {
        amount: format_currency(income_data.total - expense_data.total),
        rate: format_percentage(calculate_savings_rate(income_data.total, expense_data.total))
      }
    }
  end

  # Generate financial insights for income statement
  def financial_insights(period: Period.current_month)
    expense_data = expense_totals(period: period)
    income_data = income_totals(period: period)

    # Compare with previous period
    prev_period = get_previous_period(period)
    prev_expense_data = expense_totals(period: prev_period)
    prev_income_data = income_totals(period: prev_period)

    # Calculate changes
    income_change = income_data.total - prev_income_data.total
    expense_change = expense_data.total - prev_expense_data.total

    # Calculate percentages
    income_change_pct = prev_income_data.total.zero? ? 0 : (income_change / prev_income_data.total.to_f * 100)
    expense_change_pct = prev_expense_data.total.zero? ? 0 : (expense_change / prev_expense_data.total.to_f * 100)

    # Find top categories
    top_expense_categories = expense_data.category_totals
      .reject { |ct| ct.category.subcategory? }
      .sort_by { |ct| -ct.total }
      .take(3)

    top_income_categories = income_data.category_totals
      .reject { |ct| ct.category.subcategory? }
      .sort_by { |ct| -ct.total }
      .take(3)

    current_savings_rate = calculate_savings_rate(income_data.total, expense_data.total)
    previous_savings_rate = calculate_savings_rate(prev_income_data.total, prev_expense_data.total)

    {
      summary: "For #{period_name(period)}, your net income is #{format_currency(income_data.total - expense_data.total)} with a savings rate of #{format_percentage(current_savings_rate)}.",
      period_comparison: {
        previous_period: period_name(prev_period),
        income_change: {
          amount: format_currency(income_change),
          percentage: format_percentage(income_change_pct),
          trend: income_change > 0 ? "increasing" : (income_change < 0 ? "decreasing" : "stable")
        },
        expense_change: {
          amount: format_currency(expense_change),
          percentage: format_percentage(expense_change_pct),
          trend: expense_change > 0 ? "increasing" : (expense_change < 0 ? "decreasing" : "stable")
        },
        savings_rate_change: format_percentage(current_savings_rate - previous_savings_rate)
      },
      expense_insights: {
        top_categories: top_expense_categories.map do |ct|
          {
            name: ct.category.name,
            amount: format_currency(ct.total),
            percentage: format_percentage(ct.weight)
          }
        end,
        daily_average: format_currency(expense_data.total / period.days),
        monthly_estimate: format_currency(expense_data.total * (30.0 / period.days))
      },
      income_insights: {
        top_sources: top_income_categories.map do |ct|
          {
            name: ct.category.name,
            amount: format_currency(ct.total),
            percentage: format_percentage(ct.weight)
          }
        end,
        monthly_estimate: format_currency(income_data.total * (30.0 / period.days))
      }
    }
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

      uncategorized_category = family.categories.uncategorized

      category_totals = [ *categories, uncategorized_category ].map do |category|
        subcategory = categories.find { |c| c.id == category.parent_id }

        parent_category_total = totals.select { |t| t.category_id == category.id }&.sum(&:total) || 0

        children_totals = if category == uncategorized_category
          0
        else
          totals.select { |t| t.parent_category_id == category.id }&.sum(&:total) || 0
        end

        category_total = parent_category_total + children_totals

        weight = (category_total.zero? ? 0 : category_total.to_f / classification_total) * 100

        CategoryTotal.new(
          category: category,
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
      @family_stats ||= {}
      @family_stats[interval] ||= FamilyStats.new(family, interval:).call
    end

    def category_stats(interval: "month")
      @category_stats ||= {}
      @category_stats[interval] ||= CategoryStats.new(family, interval:).call
    end

    def totals_query(transactions_scope:)
      @totals_query_cache ||= {}
      cache_key = Digest::MD5.hexdigest(transactions_scope.to_sql)
      @totals_query_cache[cache_key] ||= Totals.new(family, transactions_scope: transactions_scope).call
    end

    def monetizable_currency
      family.currency
    end

    def calculate_savings_rate(total_income, total_expenses)
      return 0 if total_income.zero?
      savings = total_income - total_expenses
      rate = (savings / total_income.to_f) * 100
      rate.round(2)
    end

    # Get previous period for comparison
    def get_previous_period(period)
      if period.is_a?(Period)
        # For custom periods, create a period of same length ending right before this period starts
        length = (period.end_date - period.start_date).to_i
        Period.new(start_date: period.start_date - length.days - 1.day, end_date: period.start_date - 1.day)
      else
        # Default to previous month
        current_month = Date.today.beginning_of_month..Date.today.end_of_month
        previous_month = 1.month.ago.beginning_of_month..1.month.ago.end_of_month
        Period.new(start_date: previous_month.begin, end_date: previous_month.end)
      end
    end

    # Get a human-readable name for a period
    def period_name(period)
      if period == Period.current_month
        "Current Month"
      elsif period == Period.previous_month
        "Previous Month"
      elsif period == Period.year_to_date
        "Year to Date"
      elsif period == Period.previous_year
        "Previous Year"
      else
        "#{format_date(period.start_date)} to #{format_date(period.end_date)}"
      end
    end
end
