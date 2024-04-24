class Family < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :transactions, through: :accounts
  has_many :transaction_categories, dependent: :destroy, class_name: "Transaction::Category"

  def snapshot(period = Period.all)
    query = accounts.active.joins(:balances)
      .where("account_balances.currency = ?", self.currency)
      .select(
        "account_balances.currency",
        "account_balances.date",
        "SUM(CASE WHEN accounts.classification = 'liability' THEN account_balances.balance ELSE 0 END) AS liabilities",
        "SUM(CASE WHEN accounts.classification = 'asset' THEN account_balances.balance ELSE 0 END) AS assets",
        "SUM(CASE WHEN accounts.classification = 'asset' THEN account_balances.balance WHEN accounts.classification = 'liability' THEN -account_balances.balance ELSE 0 END) AS net_worth",
      )
      .group("account_balances.date, account_balances.currency")
      .order("account_balances.date")

    query = query.where("account_balances.date >= ?", period.date_range.begin) if period.date_range.begin
    query = query.where("account_balances.date <= ?", period.date_range.end) if period.date_range.end
    result = query.to_a

    {
      asset_series: TimeSeries.new(result.map { |r| { date: r.date, value: Money.new(r.assets, r.currency) } }),
      liability_series: TimeSeries.new(result.map { |r| { date: r.date, value: Money.new(r.liabilities, r.currency) } }),
      net_worth_series: TimeSeries.new(result.map { |r| { date: r.date, value: Money.new(r.net_worth, r.currency) } })
    }
  end

  def snapshot_account_transactions
    period = Period.last_30_days

    results = accounts.active.joins(:transactions)
      .select(
        "accounts.*",
        "COALESCE(SUM(amount) FILTER (WHERE amount > 0), 0) AS spending",
        "COALESCE(SUM(-amount) FILTER (WHERE amount < 0), 0) AS income"
      )
      .where("transactions.date >= ?", period.date_range.begin)
      .where("transactions.date <= ?", period.date_range.end)
      .group("id")
      .to_a

    {
      top_spenders: results.sort_by(&:spending).select { |a| a.spending > 0 }.reverse,
      top_earners: results.sort_by(&:income).select { |a| a.income > 0 }.reverse
    }
  end

  def snapshot_transactions
    rolling_totals = Transaction.daily_rolling_totals(transactions, period: Period.last_30_days, currency: self.currency)

    spending = []
    income = []
    rolling_totals.each do |r|
      spending << {
        date: r.date,
        value: Money.new(r.rolling_spend, self.currency)
      }

      income << {
        date: r.date,
        value: Money.new(r.rolling_income, self.currency)
      }
    end

    {
      income_series: TimeSeries.new(income, favorable_direction: "up"),
      spending_series: TimeSeries.new(spending, favorable_direction: "down")
    }
  end

  def effective_start_date
    accounts.active.joins(:balances).minimum("account_balances.date") || Date.current
  end

  def net_worth
    assets - liabilities
  end

  def assets
    Money.new(accounts.active.assets.map { |account| account.balance_money.exchange_to(currency) || 0 }.sum, currency)
  end

  def liabilities
    Money.new(accounts.active.liabilities.map { |account| account.balance_money.exchange_to(currency) || 0 }.sum, currency)
  end

  def sync_accounts
    accounts.each { |account| account.sync_later if account.can_sync? }
  end
end
