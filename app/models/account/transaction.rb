class Account::Transaction < ApplicationRecord
  include Account::Entryable

  belongs_to :transfer, optional: true, class_name: "Account::Transfer"
  belongs_to :category, optional: true
  belongs_to :merchant, optional: true
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  accepts_nested_attributes_for :taggings, allow_destroy: true

  scope :active, -> { where(excluded: false) }
  scope :inflows, -> { where("amount <= 0") }
  scope :outflows, -> { where("amount > 0") }
  scope :without_transfers, -> { where(marked_as_transfer: false) }
  scope :with_converted_amount, ->(currency) {
    # Join with exchange rates to convert the amount to the given currency
    # If no rate is available, exclude the transaction from the results
    joins(:entry).select(
      "account_entries.*",
      "account_entries.amount * COALESCE(er.rate, 1) AS converted_amount"
    )
                 .joins(sanitize_sql_array([ "LEFT JOIN exchange_rates er ON account_entries.date = er.date AND account_entries.currency = er.base_currency AND er.converted_currency = ?", currency ]))
                 .where("er.rate IS NOT NULL OR account_entries.currency = ?", currency)
  }

  def inflow?
    entry.amount <= 0
  end

  def outflow?
    entry.amount > 0
  end

  def transfer?
    marked_as_transfer
  end

  class << self
    def mark_transfers!
      update_all marked_as_transfer: true

      # Attempt to "auto match" and save a transfer if 2 transactions selected
      Account::Transfer.new(transactions: all).save if all.count == 2
    end

    def daily_totals(transactions, currency, period: Period.last_30_days)
      # Sum spending and income for each day in the period with the given currency
      select(
        "gs.date",
        "COALESCE(SUM(converted_amount) FILTER (WHERE converted_amount > 0), 0) AS spending",
        "COALESCE(SUM(-converted_amount) FILTER (WHERE converted_amount < 0), 0) AS income"
      )
        .from(transactions.without_transfers.with_converted_amount(currency), :t)
        .joins(sanitize_sql([ "RIGHT JOIN generate_series(?, ?, interval '1 day') AS gs(date) ON t.date = gs.date", period.date_range.first, period.date_range.last ]))
        .group("gs.date")
    end

    def daily_rolling_totals(transactions, currency, period: Period.last_30_days)
      # Extend the period to include the rolling window
      period_with_rolling = period.extend_backward(period.date_range.count.days)

      # Aggregate the rolling sum of spending and income based on daily totals
      rolling_totals = from(daily_totals(transactions, currency, period: period_with_rolling))
                         .select(
                           "*",
                           sanitize_sql_array([ "SUM(spending) OVER (ORDER BY date RANGE BETWEEN INTERVAL ? PRECEDING AND CURRENT ROW) as rolling_spend", "#{period.date_range.count} days" ]),
                           sanitize_sql_array([ "SUM(income) OVER (ORDER BY date RANGE BETWEEN INTERVAL ? PRECEDING AND CURRENT ROW) as rolling_income", "#{period.date_range.count} days" ])
                         )
                         .order(:date)

      # Trim the results to the original period
      select("*").from(rolling_totals).where("date >= ?", period.date_range.first)
    end

    def search(params)
      query = all
      query = query.joins("LEFT JOIN categories ON categories.id = account_transactions.category_id").where(categories: { name: params[:categories] }) if params[:categories].present?
      query = query.joins("LEFT JOIN merchants ON merchants.id = account_transactions.merchant_id").where(merchants: { name: params[:merchants] }) if params[:merchants].present?
      query
    end

    def requires_search?(params)
      searchable_keys.any? { |key| params.key?(key) }
    end

    private

      def searchable_keys
        %i[ categories merchants ]
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
