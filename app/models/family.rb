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

    {
      asset_series: MoneySeries.new(query, { trend_type: :asset, amount_accessor: "assets", fallback: self.assets }),
      liability_series: MoneySeries.new(query, { trend_type: :liability, amount_accessor: "liabilities", fallback: self.liabilities }),
      net_worth_series: MoneySeries.new(query, { trend_type: :asset, amount_accessor: "net_worth", fallback: self.net_worth })
    }
  end

  def effective_start_date
    accounts.active.joins(:balances).minimum("account_balances.date") || Date.current
  end

  def net_worth
    total = accounts.active.reduce(0) do |sum, account|
      balance = account.balance
      balance = ExchangeRate.convert(account.currency, self.currency, balance) unless account.currency == self.currency
      balance = balance.nil? ? 0 : balance
      balance *= -1 if account.classification == "liability"
      sum + balance
    end
    Money.new(total, self.currency)
  end

  def assets
    total_assets = accounts.active.assets.reduce(0) do |sum, account|
      balance = account.balance
      balance = ExchangeRate.convert(account.currency, self.currency, balance) unless account.currency == self.currency
      balance = balance.nil? ? 0 : balance
      sum + balance
    end
    Money.new(total_assets, self.currency)
  end

  def liabilities
    total_liabilities = accounts.active.liabilities.reduce(0) do |sum, account|
      balance = account.balance
      balance = ExchangeRate.convert(account.currency, self.currency, balance) unless account.currency == self.currency
      balance = balance.nil? ? 0 : balance
      sum + balance
    end
    Money.new(total_liabilities, self.currency)
  end
end
