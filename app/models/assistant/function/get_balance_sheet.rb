class Assistant::Function::GetBalanceSheet < Assistant::Function
  include ActiveSupport::NumberHelper

  class << self
    def name
      "get_balance_sheet"
    end

    def description
      <<~INSTRUCTIONS
        Use this to get the user's balance sheet with varying amounts of historical data.

        This is great for answering questions like:
        - What is the user's net worth?  What is it composed of?
        - How has the user's wealth changed over time?
      INSTRUCTIONS
    end
  end

  def call(params = {})
    observation_start_date = [ 5.years.ago.to_date, family.oldest_entry_date ].max

    period = Period.custom(start_date: observation_start_date, end_date: Date.current)

    {
      as_of_date: Date.current,
      oldest_account_start_date: family.oldest_entry_date,
      currency: family.currency,
      net_worth: {
        current: family.balance_sheet.net_worth_money.format,
        monthly_history: historical_data(period)
      },
      assets: {
        current: family.balance_sheet.total_assets_money.format,
        monthly_history: historical_data(period, classification: "asset")
      },
      liabilities: {
        current: family.balance_sheet.total_liabilities_money.format,
        monthly_history: historical_data(period, classification: "liability")
      },
      insights: insights_data
    }
  end

  private
    def historical_data(period, classification: nil)
      scope = family.accounts.active
      scope = scope.where(classification: classification) if classification.present?

      if period.start_date == Date.current
        []
      else
        balance_series = scope.balance_series(
          currency: family.currency,
          period: period,
          interval: "1 month",
          favorable_direction: "up",
        )

        to_ai_time_series(balance_series)
      end
    end

    def insights_data
      assets = family.balance_sheet.total_assets
      liabilities = family.balance_sheet.total_liabilities
      ratio = liabilities.zero? ? 0 : (liabilities / assets.to_f)

      {
        debt_to_asset_ratio: number_to_percentage(ratio * 100, precision: 0)
      }
    end
end
