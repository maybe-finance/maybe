class Transaction < ApplicationRecord
  include Monetizable

  belongs_to :account
  belongs_to :category, optional: true
  belongs_to :merchant, optional: true

  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  validates :name, :date, :amount, :account, presence: true

  monetize :amount

  scope :ordered, -> { order(date: :desc) }
  scope :inflows, -> { where("amount <= 0") }
  scope :outflows, -> { where("amount > 0") }
  scope :active, -> { where(excluded: false) }
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

  def self.daily_totals(transactions, period: Period.last_30_days, currency: Current.family.currency)
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

  def self.daily_rolling_totals(transactions, period: Period.last_30_days, currency: Current.family.currency)
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

  def self.ransackable_attributes(auth_object = nil)
    %w[name amount date]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[category merchant account]
  end
end
