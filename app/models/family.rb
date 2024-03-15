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

    query = query.where("account_balances.date BETWEEN ? AND ?", period.date_range.begin, period.date_range.end) if period.date_range

    result = query.to_a

    {
      asset_series: TimeSeries.new(result.map { |r| { date: r.date, value: r.assets } }),
      liability_series: TimeSeries.new(result.map { |r| { date: r.date, value: r.liabilities } }),
      net_worth_series: TimeSeries.new(result.map { |r| { date: r.date, value: r.net_worth } })
    }
  end

  def effective_start_date
    accounts.active.joins(:balances).minimum("account_balances.date") || Date.current
  end

  def net_worth
    accounts.active.sum("CASE WHEN classification = 'asset' THEN balance ELSE -balance END")
  end

  def assets
   accounts.active.assets.sum(:balance)
  end

  def liabilities
    accounts.active.liabilities.sum(:balance)
  end
end
