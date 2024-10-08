class Family < ApplicationRecord
  include Providable

  has_many :users, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :institutions, dependent: :destroy
  has_many :imports, dependent: :destroy
  has_many :transactions, through: :accounts
  has_many :entries, through: :accounts
  has_many :categories, dependent: :destroy
  has_many :merchants, dependent: :destroy
  has_many :issues, through: :accounts

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }

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
    results = accounts.active.joins(:entries)
                      .select(
                        "accounts.*",
                        "COALESCE(SUM(account_entries.amount) FILTER (WHERE account_entries.amount > 0), 0) AS spending",
                        "COALESCE(SUM(-account_entries.amount) FILTER (WHERE account_entries.amount < 0), 0) AS income"
                      )
                      .where("account_entries.date >= ?", period.date_range.begin)
                      .where("account_entries.date <= ?", period.date_range.end)
                      .where("account_entries.marked_as_transfer = ?", false)
                      .where("account_entries.entryable_type = ?", "Account::Transaction")
                      .group("accounts.id")
                      .having("SUM(ABS(account_entries.amount)) > 0")
                      .to_a

    results.each do |r|
      r.define_singleton_method(:savings_rate) do
        (income - spending) / income
      end
    end

    {
      top_spenders: results.sort_by(&:spending).select { |a| a.spending > 0 }.reverse,
      top_earners: results.sort_by(&:income).select { |a| a.income > 0 }.reverse,
      top_savers: results.sort_by { |a| a.savings_rate }.reverse
    }
  end

  def snapshot_transactions
    candidate_entries = entries.account_transactions.without_transfers
    rolling_totals = Account::Entry.daily_rolling_totals(candidate_entries, self.currency, period: Period.last_30_days)

    spending = []
    income = []
    savings = []
    rolling_totals.each do |r|
      spending << {
        date: r.date,
        value: Money.new(r.rolling_spend, self.currency)
      }

      income << {
        date: r.date,
        value: Money.new(r.rolling_income, self.currency)
      }

      savings << {
        date: r.date,
        value: r.rolling_income != 0 ? (r.rolling_income - r.rolling_spend) / r.rolling_income : 0.to_d
      }
    end

    {
      income_series: TimeSeries.new(income, favorable_direction: "up"),
      spending_series: TimeSeries.new(spending, favorable_direction: "down"),
      savings_rate_series: TimeSeries.new(savings, favorable_direction: "up")
    }
  end

  def net_worth
    assets - liabilities
  end

  def assets
    Money.new(accounts.active.assets.map { |account| account.balance_money.exchange_to(currency, fallback_rate: 0) }.sum, currency)
  end

  def liabilities
    Money.new(accounts.active.liabilities.map { |account| account.balance_money.exchange_to(currency, fallback_rate: 0) }.sum, currency)
  end

  def sync(start_date: nil)
    accounts.active.each do |account|
      if account.needs_sync?
        account.sync_later(start_date: start_date || account.last_sync_date)
      end
    end

    update! last_synced_at: Time.now
  end

  def needs_sync?
    last_synced_at.nil? || last_synced_at.to_date < Date.current
  end

  def synth_usage
    self.class.synth_provider&.usage
  end

  def subscribed?
    stripe_subscription_status.present? && stripe_subscription_status == "active"
  end

  def primary_user
    users.order(:created_at).first
  end
end
