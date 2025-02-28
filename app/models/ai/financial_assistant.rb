module Ai
  class FinancialAssistant
    attr_reader :family, :client

    def initialize(family, client: nil)
      @family = family
      @client = client || OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
    end

    def query(question)
      # This is a simplified implementation that we'll expand later
      "This is a placeholder response. The actual GPT integration will be implemented in the next step."
    end

    # Define the functions that can be called by GPT
    def financial_function_definitions
      [
        {
          name: "get_balance_sheet",
          description: "Get current balance sheet information including net worth, assets, and liabilities",
          parameters: {
            type: "object",
            properties: {},
            required: []
          }
        },
        {
          name: "get_income_statement",
          description: "Get income statement data for a specific time period",
          parameters: {
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
        }
      ]
    end

    private

      # Execute the get_balance_sheet function
      def execute_get_balance_sheet(params = {})
        balance_sheet = BalanceSheet.new(family)
        balance_sheet.to_ai_readable_hash
      end

      # Execute the get_income_statement function
      def execute_get_income_statement(params = {})
        income_statement = IncomeStatement.new(family)
        period = get_period_from_param(params[:period])
        income_statement.to_ai_readable_hash(period: period)
      end

      # Helper to convert period string to a Period object
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
end
