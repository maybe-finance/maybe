class Assistant::Function::GetExpenseCategories < Assistant::Function
  class << self
    def name
      "get_expense_categories"
    end

    def description
      "Get top expense categories for a specific time period"
    end

    def parameters
      {
        type: "object",
        properties: {
          period: {
            type: "string",
            enum: [ "current_month", "previous_month", "year_to_date", "previous_year" ],
            description: "The time period for the expense categories data"
          },
          limit: {
            type: "integer",
            description: "Number of top categories to return",
            default: 5
          }
        },
        required: []
      }
    end
  end

  def call(params = {})
    income_statement = IncomeStatement.new(family)
    period = get_period_from_param(params["period"])
    limit = params["limit"] || 5

    expense_data = income_statement.expense_totals(period: period)

    {
      period: format_period(period),
      total_expenses: format_currency(expense_data.total),
      top_categories: get_top_categories(expense_data, limit),
      currency: family.currency
    }
  end

  private

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

    def format_period(period)
      {
        start_date: period.start_date.to_s,
        end_date: period.end_date.to_s
      }
    end

    def get_top_categories(expense_data, limit)
      expense_data.category_totals
        .reject { |ct| ct.category.subcategory? }
        .sort_by { |ct| -ct.total }
        .take(limit)
        .map { |ct| format_category(ct) }
    end

    def format_category(category_total)
      {
        name: category_total.category.name,
        amount: format_currency(category_total.total),
        percentage: category_total.weight.round(2)
      }
    end

    def format_currency(amount)
      Money.new(amount, family.currency).format
    end
end
