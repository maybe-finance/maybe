class Transaction < ApplicationRecord
  include Monetizable

  monetize :amount

  belongs_to :account
  belongs_to :category, optional: true
  belongs_to :merchant, optional: true
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings
  accepts_nested_attributes_for :taggings, allow_destroy: true

  validates :name, :date, :amount, :account, presence: true

  scope :ordered, -> { order(date: :desc) }
  scope :active, -> { where(excluded: false) }
  scope :inflows, -> { where("amount <= 0") }
  scope :outflows, -> { where("amount > 0") }
  scope :by_name, ->(name) { where("transactions.name ILIKE ?", "%#{name}%") }
  scope :with_categories, ->(categories) { joins(:category).where(transaction_categories: { name: categories }) }
  scope :with_accounts, ->(accounts) { joins(:account).where(accounts: { name: accounts }) }
  scope :with_account_ids, ->(account_ids) { joins(:account).where(accounts: { id: account_ids }) }
  scope :with_merchants, ->(merchants) { joins(:merchant).where(transaction_merchants: { name: merchants }) }
  scope :on_or_after_date, ->(date) { where("transactions.date >= ?", date) }
  scope :on_or_before_date, ->(date) { where("transactions.date <= ?", date) }
  scope :with_converted_amount, ->(currency = Current.family.currency) {
    # Join with exchange rates to convert the amount to the given currency
    # If no rate is available, exclude the transaction from the results
    select(
      "transactions.*",
      "transactions.amount * COALESCE(er.rate, 1) AS converted_amount"
    )
      .joins(sanitize_sql_array([ "LEFT JOIN exchange_rates er ON transactions.date = er.date AND transactions.currency = er.base_currency AND er.converted_currency = ?", currency ]))
      .where("er.rate IS NOT NULL OR transactions.currency = ?", currency)
  }

  def inflow?
    amount <= 0
  end

  def outflow?
    amount > 0
  end

  def sync_account_later
    if destroyed?
      sync_start_date = previous_transaction_date
    else
      sync_start_date = [ date_previously_was, date ].compact.min
    end

    account.sync_later(sync_start_date)
  end

  class << self
    def daily_totals(transactions, period: Period.last_30_days, currency: Current.family.currency)
      # Sum spending and income for each day in the period with the given currency
      select(
        "gs.date",
        "COALESCE(SUM(converted_amount) FILTER (WHERE converted_amount > 0), 0) AS spending",
        "COALESCE(SUM(-converted_amount) FILTER (WHERE converted_amount < 0), 0) AS income"
      )
        .from(transactions.with_converted_amount(currency), :t)
        .joins(sanitize_sql([ "RIGHT JOIN generate_series(?, ?, interval '1 day') AS gs(date) ON t.date = gs.date", period.date_range.first, period.date_range.last ]))
        .group("gs.date")
    end

    def daily_rolling_totals(transactions, period: Period.last_30_days, currency: Current.family.currency)
      # Extend the period to include the rolling window
      period_with_rolling = period.extend_backward(period.date_range.count.days)

      # Aggregate the rolling sum of spending and income based on daily totals
      rolling_totals = from(daily_totals(transactions, period: period_with_rolling, currency: currency))
                         .select(
                           "*",
                           sanitize_sql_array([ "SUM(spending) OVER (ORDER BY date RANGE BETWEEN INTERVAL ? PRECEDING AND CURRENT ROW) as rolling_spend", "#{period.date_range.count} days" ]),
                           sanitize_sql_array([ "SUM(income) OVER (ORDER BY date RANGE BETWEEN INTERVAL ? PRECEDING AND CURRENT ROW) as rolling_income", "#{period.date_range.count} days" ])
                         )
                         .order("date")

      # Trim the results to the original period
      select("*").from(rolling_totals).where("date >= ?", period.date_range.first)
    end

    def search(params)
      query = all
      query = query.by_name(params[:search]) if params[:search].present?
      query = query.with_categories(params[:categories]) if params[:categories].present?
      query = query.with_accounts(params[:accounts]) if params[:accounts].present?
      query = query.with_account_ids(params[:account_ids]) if params[:account_ids].present?
      query = query.with_merchants(params[:merchants]) if params[:merchants].present?
      query = query.on_or_after_date(params[:start_date]) if params[:start_date].present?
      query = query.on_or_before_date(params[:end_date]) if params[:end_date].present?
      query
    end
  end

  private

    def previous_transaction_date
      self.account
          .transactions
          .where("date < ?", date)
          .order(date: :desc)
          .first&.date
    end
end
