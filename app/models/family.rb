class Family < ApplicationRecord
  include Plaidable, Syncable

  DATE_FORMATS = [ "%m-%d-%Y", "%d.%m.%Y", "%d-%m-%Y", "%Y-%m-%d", "%d/%m/%Y", "%Y/%m/%d", "%m/%d/%Y", "%e/%m/%Y", "%Y.%m.%d" ]

  include Providable

  has_many :users, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :imports, dependent: :destroy
  has_many :transactions, through: :accounts
  has_many :entries, through: :accounts
  has_many :categories, dependent: :destroy
  has_many :merchants, dependent: :destroy
  has_many :issues, through: :accounts
  has_many :holdings, through: :accounts
  has_many :plaid_items, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :budget_categories, through: :budgets

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :date_format, inclusion: { in: DATE_FORMATS }

  def sync_data(start_date: nil)
    update!(last_synced_at: Time.current)

    accounts.manual.each do |account|
      account.sync_data(start_date: start_date)
    end

    plaid_data = []

    plaid_items.each do |plaid_item|
      plaid_data << plaid_item.sync_data(start_date: start_date)
    end

    plaid_data
  end

  def post_sync
    broadcast_refresh
  end

  def syncing?
    Sync.where(
      "(syncable_type = 'Family' AND syncable_id = ?) OR
       (syncable_type = 'Account' AND syncable_id IN (SELECT id FROM accounts WHERE family_id = ? AND plaid_account_id IS NULL)) OR
       (syncable_type = 'PlaidItem' AND syncable_id IN (SELECT id FROM plaid_items WHERE family_id = ?))",
      id, id, id
    ).where(status: [ "pending", "syncing" ]).exists?
  end

  def eu?
    country != "US" && country != "CA"
  end

  def get_link_token(webhooks_url:, redirect_url:, accountable_type: nil, region: :us)
    provider = if region.to_sym == :eu
      self.class.plaid_eu_provider
    else
      self.class.plaid_us_provider
    end

    provider.get_link_token(
      user_id: id,
      webhooks_url: webhooks_url,
      redirect_url: redirect_url,
      accountable_type: accountable_type,
    ).link_token
  end

  def income_categories_with_totals(date: Date.current)
    categories_with_stats(classification: "income", date: date)
  end

  def expense_categories_with_totals(date: Date.current)
    categories_with_stats(classification: "expense", date: date)
  end

  def category_stats
    CategoryStats.new(self)
  end

  def budgeting_stats
    BudgetingStats.new(self)
  end

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
    results = accounts.active
                      .joins(:entries)
                      .joins("LEFT JOIN transfers ON (transfers.inflow_transaction_id = account_entries.entryable_id OR transfers.outflow_transaction_id = account_entries.entryable_id)")
                      .select(
                        "accounts.*",
                        "COALESCE(SUM(account_entries.amount) FILTER (WHERE account_entries.amount > 0), 0) AS spending",
                        "COALESCE(SUM(-account_entries.amount) FILTER (WHERE account_entries.amount < 0), 0) AS income"
                      )
                      .where("account_entries.date >= ?", period.date_range.begin)
                      .where("account_entries.date <= ?", period.date_range.end)
                      .where("account_entries.entryable_type = 'Account::Transaction'")
                      .where("transfers.id IS NULL")
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
    candidate_entries = entries.account_transactions.incomes_and_expenses
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
        value: r.rolling_income != 0 ? ((r.rolling_income - r.rolling_spend) / r.rolling_income) : 0.to_d
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

  def synth_usage
    self.class.synth_provider&.usage
  end

  def synth_overage?
    self.class.synth_provider&.usage&.utilization.to_i >= 100
  end

  def synth_valid?
    self.class.synth_provider&.healthy?
  end

  def subscribed?
    stripe_subscription_status == "active"
  end

  def primary_user
    users.order(:created_at).first
  end

  def oldest_entry_date
    entries.order(:date).first&.date || Date.current
  end

  private
    CategoriesWithTotals = Struct.new(:total_money, :category_totals, keyword_init: true)
    CategoryWithStats = Struct.new(:category, :amount_money, :percentage, keyword_init: true)

    def categories_with_stats(classification:, date: Date.current)
      totals = category_stats.month_category_totals(date: date)

      classified_totals = totals.category_totals.select { |t| t.classification == classification }

      if classification == "income"
        total = totals.total_income
        categories_scope = categories.incomes
      else
        total = totals.total_expense
        categories_scope = categories.expenses
      end

      categories_with_uncategorized = categories_scope + [ categories_scope.uncategorized ]

      CategoriesWithTotals.new(
        total_money: Money.new(total, currency),
        category_totals: categories_with_uncategorized.map do |category|
          ct = classified_totals.find { |ct| ct.category_id == category&.id }

          CategoryWithStats.new(
            category: category,
            amount_money: Money.new(ct&.amount || 0, currency),
            percentage: ct&.percentage || 0
          )
        end
      )
    end
end
