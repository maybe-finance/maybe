class Assistant::Function::ComparePeriods < Assistant::Function
  class << self
    def name
      "compare_periods"
    end

    def description
      "Compare financial data between two periods"
    end

    def parameters
      {
        type: "object",
        properties: {
          period1: {
            type: "string",
            enum: [ "current_month", "previous_month", "year_to_date", "previous_year" ],
            description: "First period for comparison"
          },
          period2: {
            type: "string",
            enum: [ "current_month", "previous_month", "year_to_date", "previous_year" ],
            description: "Second period for comparison"
          }
        },
        required: [ "period1", "period2" ],
        additionalProperties: false
      }
    end
  end

  def call(params = {})
    period1 = get_period_from_param(params["period1"])
    period2 = get_period_from_param(params["period2"])

    income_statement = IncomeStatement.new(family)
    period1_data = get_period_data(income_statement, period1)
    period2_data = get_period_data(income_statement, period2)

    {
      period1: format_period_data(period1_data, params["period1"]),
      period2: format_period_data(period2_data, params["period2"]),
      differences: calculate_differences(period1_data, period2_data),
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

    def get_period_data(income_statement, period)
      {
        period: period,
        income: income_statement.income_totals(period: period),
        expenses: income_statement.expense_totals(period: period)
      }
    end

    def format_period_data(data, period_name)
      net_income = data[:income].total - data[:expenses].total
      {
        name: get_period_name(period_name),
        start_date: data[:period].start_date.to_s,
        end_date: data[:period].end_date.to_s,
        total_income: format_currency(data[:income].total),
        total_expenses: format_currency(data[:expenses].total),
        net_income: format_currency(net_income)
      }
    end

    def calculate_differences(period1_data, period2_data)
      income_diff = period1_data[:income].total - period2_data[:income].total
      expenses_diff = period1_data[:expenses].total - period2_data[:expenses].total
      net_income_diff = income_diff - expenses_diff

      {
        income: format_currency(income_diff),
        income_percent: calculate_percentage_change(income_diff, period2_data[:income].total),
        expenses: format_currency(expenses_diff),
        expenses_percent: calculate_percentage_change(expenses_diff, period2_data[:expenses].total),
        net_income: format_currency(net_income_diff)
      }
    end

    def calculate_percentage_change(diff, original)
      return 0 if original.zero?
      (diff / original.to_f * 100).round(2)
    end

    def get_period_name(period_param)
      case period_param
      when "current_month"
        "Current Month"
      when "previous_month"
        "Previous Month"
      when "year_to_date"
        "Year to Date"
      when "previous_year"
        "Previous Year"
      else
        "Custom Period"
      end
    end

    def format_currency(amount)
      Money.new(amount, family.currency).format
    end
end
