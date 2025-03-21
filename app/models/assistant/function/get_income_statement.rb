class Assistant::Function::GetIncomeStatement < Assistant::Function
  class << self
    def name
      "get_income_statement"
    end

    def description
      "Get income statement data for a specific time period"
    end

    def parameters
      {
        type: "object",
        properties: {
          period: {
            type: "string",
            enum: [ "current_month", "previous_month", "year_to_date", "previous_year" ],
            description: "The time period for the income statement data"
          }
        },
        required: []
      }
    end
  end

  def call(params = {})
    income_statement = IncomeStatement.new(family)
    period = get_period_from_param(params["period"])
    income_statement.to_ai_readable_hash(period: period)
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
end
