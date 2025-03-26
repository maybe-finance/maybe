class Assistant::Function::GetAccounts < Assistant::Function
  class << self
    def name
      "get_accounts"
    end

    def description
      "Use this to see what accounts the user has along with their current and historical balances"
    end
  end

  def call(params = {})
    {
      as_of_date: Date.current,
      accounts: family.accounts.includes(:balances).map do |account|
        series_start_date = [ account.start_date, 5.years.ago.to_date ].max
        all_dates = Period.custom(start_date: series_start_date, end_date: Date.current)
        balance_series = account.balance_series(period: all_dates, interval: "1 month")

        {
          name: account.name,
          balance: account.balance,
          currency: account.currency,
          balance_formatted: account.balance_money.format,
          classification: account.classification,
          type: account.accountable_type,
          start_date: account.start_date,
          is_plaid_linked: account.plaid_account_id.present?,
          is_active: account.is_active,
          historical_balances: {
            start_date: balance_series.start_date,
            end_date: balance_series.end_date,
            currency: account.currency,
            interval: balance_series.interval,
            order: "chronological",
            balances: balance_series.values.map { |value| { date: value.date, balance_formatted: value.trend.current.format } }
          }
        }
      end
    }
  end
end
