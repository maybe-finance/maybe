class Transaction < ApplicationRecord
  include Monetizable

  belongs_to :account
  belongs_to :category, optional: true
  belongs_to :merchant, optional: true

  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  validates :name, :date, :amount, :account, presence: true

  monetize :amount

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

  def self.build_filter_list(params, family)
    filters = []
    valid_params = {}

    date_filters = { gteq: nil, lteq: nil }

    if params
      params.each do |key, value|
        next if value.blank?

        case key
        when "account_id_in"
          valid_accounts = value.select do |account_id|
            account = family.accounts.find_by(id: account_id)
            filters << { type: "account", value: account, original: { key: key, value: account_id } } if account.present?
            account.present?
          end
          valid_params[key] = valid_accounts unless valid_accounts.empty?
        when "category_id_in"
          valid_categories = value.select do |category_id|
            category = family.transaction_categories.find_by(id: category_id)
            filters << { type: "category", value: category, original: { key: key, value: category_id } } if category.present?
            category.present?
          end
          valid_params[key] = valid_categories unless valid_categories.empty?
        when "merchant_id_in"
          valid_merchants = value.select do |merchant_id|
            merchant = family.transaction_merchants.find_by(id: merchant_id)
            filters << { type: "merchant", value: merchant, original: { key: key, value: merchant_id } } if merchant.present?
            merchant.present?
          end
          valid_params[key] = valid_merchants unless valid_merchants.empty?
        when "category_name_or_merchant_name_or_account_name_or_name_cont"
          filters << { type: "search", value: value, original: { key: key, value: nil } }
          valid_params[key] = value
        when "date_gteq"
          date_filters[:gteq] = value
          valid_params[key] = value
        when "date_lteq"
          date_filters[:lteq] = value
          valid_params[key] = value
        end
      end

      unless date_filters.values.compact.empty?
        filters << { type: "date_range", value: date_filters, original: { key: "date_range", value: nil } }
      end
    end

    [ filters, valid_params ]
  end
end
