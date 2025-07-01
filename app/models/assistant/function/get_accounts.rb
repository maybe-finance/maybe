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
        {
          name: account.name,
          balance: account.balance,
          currency: account.currency,
          balance_formatted: account.balance_money.format,
          classification: account.classification,
          type: account.accountable_type,
          start_date: account.start_date,
          is_plaid_linked: account.plaid_account_id.present?,
          status: account.status,
          historical_balances: historical_balances(account)
        }
      end
    }
  end

  private
    def historical_balances(account)
      start_date = [ account.start_date, 5.years.ago.to_date ].max
      period = Period.custom(start_date: start_date, end_date: Date.current)
      balance_series = account.balance_series(period: period, interval: "1 month")

      to_ai_time_series(balance_series)
    end
end
