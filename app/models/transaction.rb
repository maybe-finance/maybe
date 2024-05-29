class Transaction < ApplicationRecord
  include Monetizable

  monetize :amount

  belongs_to :account
  belongs_to :category, optional: true
  belongs_to :merchant, optional: true
  has_many :tags, through: :taggings
  has_many :taggings, as: :taggable, dependent: :destroy

  validates :name, :date, :amount, :account, presence: true

  scope :ordered, -> { order(date: :desc) }
  scope :active, -> { where(excluded: false) }
  scope :by_name, ->(name) { where("transactions.name ILIKE ?", "%#{name}%") if name.present? }
  scope :with_categories, ->(categories) { joins(:category).where(transaction_categories: { name: categories }) if categories.present? }
  scope :with_accounts, ->(accounts) { joins(:account).where(accounts: { name: accounts }) if accounts.present? }
  scope :with_merchants, ->(merchants) { joins(:merchant).where(transaction_merchants: { name: merchants }) if merchants.present? }
  scope :on_or_after_date, ->(date) { where("transactions.date >= ?", date) if date.present? }
  scope :on_or_before_date, ->(date) { where("transactions.date <= ?", date) if date.present? }
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
      all
        .by_name(params[:search])
        .with_categories(params[:categories])
        .with_accounts(params[:accounts])
        .with_merchants(params[:merchants])
        .on_or_after_date(params[:start_date])
        .on_or_before_date(params[:end_date])
    end
  end
end
