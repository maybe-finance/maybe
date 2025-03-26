class Assistant::Function::GetIncomeStatement < Assistant::Function

  class << self
    def name
      "get_income_statement"
    end

    def description
      "Use this to get income and expense insights by category, for a specific time period"
    end
  end

  def call(params = {})
    income_statement = IncomeStatement.new(family)
    period = get_period_from_param(params["period"])
    income_statement.to_ai_readable_hash(period: period)
  end

  def params_schema
    {
      type: "object",
      properties: {
        period: {
          type: "string",
          enum: [ "current_month", "previous_month", "year_to_date", "previous_year" ],
          description: "The time period for the income statement data"
        }
      },
      required: [ "period" ],
      additionalProperties: false
    }
  end

  private

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

    def get_period_from_param(period_param)
      case period_param
      when "current_month"
        Period.current_month
      when "previous_month"
        Period.previous_month
      when "year_to_date"
        Period.year_to_date
      when "previous_year"
        Period.previous_year
      else
        Period.current_month
      end
    end
end
