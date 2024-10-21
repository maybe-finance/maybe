class Account::Entry < ApplicationRecord
  include Monetizable

  monetize :amount

  belongs_to :account
  belongs_to :transfer, optional: true
  belongs_to :import, optional: true

  delegated_type :entryable, types: Account::Entryable::TYPES, dependent: :destroy
  accepts_nested_attributes_for :entryable

  validates :date, :amount, :currency, presence: true
  validates :date, uniqueness: { scope: [ :account_id, :entryable_type ] }, if: -> { account_valuation? }
  validates :date, comparison: { greater_than: -> { min_supported_date } }

  scope :chronological, -> { order(:date, :created_at) }
  scope :reverse_chronological, -> { order(date: :desc, created_at: :desc) }
  scope :without_transfers, -> { where(marked_as_transfer: false) }
  scope :with_converted_amount, ->(currency) {
    # Join with exchange rates to convert the amount to the given currency
    # If no rate is available, exclude the transaction from the results
    select(
      "account_entries.*",
      "account_entries.amount * COALESCE(er.rate, 1) AS converted_amount"
    )
      .joins(sanitize_sql_array([ "LEFT JOIN exchange_rates er ON account_entries.date = er.date AND account_entries.currency = er.from_currency AND er.to_currency = ?", currency ]))
      .where("er.rate IS NOT NULL OR account_entries.currency = ?", currency)
  }

  def sync_account_later
    if destroyed?
      sync_start_date = previous_entry&.date
    else
      sync_start_date = [ date_previously_was, date ].compact.min
    end

    account.sync_later(start_date: sync_start_date)
  end

  def inflow?
    amount <= 0 && account_transaction?
  end

  def outflow?
    amount > 0 && account_transaction?
  end

  def first_of_type?
    first_entry = account
                    .entries
                    .where("entryable_type = ?", entryable_type)
                    .order(:date)
                    .first

    first_entry&.id == id
  end

  def entryable_name_short
    entryable_type.demodulize.underscore
  end

  def trend
    @trend ||= create_trend
  end

  class << self
    # arbitrary cutoff date to avoid expensive sync operations
    def min_supported_date
      10.years.ago.to_date
    end

    def daily_totals(entries, currency, period: Period.last_30_days)
      # Sum spending and income for each day in the period with the given currency
      select(
        "gs.date",
        "COALESCE(SUM(converted_amount) FILTER (WHERE converted_amount > 0), 0) AS spending",
        "COALESCE(SUM(-converted_amount) FILTER (WHERE converted_amount < 0), 0) AS income"
      )
        .from(entries.with_converted_amount(currency), :e)
        .joins(sanitize_sql([ "RIGHT JOIN generate_series(?, ?, interval '1 day') AS gs(date) ON e.date = gs.date", period.date_range.first, period.date_range.last ]))
        .group("gs.date")
    end

    def daily_rolling_totals(entries, currency, period: Period.last_30_days)
      # Extend the period to include the rolling window
      period_with_rolling = period.extend_backward(period.date_range.count.days)

      # Aggregate the rolling sum of spending and income based on daily totals
      rolling_totals = from(daily_totals(entries, currency, period: period_with_rolling))
                         .select(
                           "*",
                           sanitize_sql_array([ "SUM(spending) OVER (ORDER BY date RANGE BETWEEN INTERVAL ? PRECEDING AND CURRENT ROW) as rolling_spend", "#{period.date_range.count} days" ]),
                           sanitize_sql_array([ "SUM(income) OVER (ORDER BY date RANGE BETWEEN INTERVAL ? PRECEDING AND CURRENT ROW) as rolling_income", "#{period.date_range.count} days" ])
                         )
                         .order(:date)

      # Trim the results to the original period
      select("*").from(rolling_totals).where("date >= ?", period.date_range.first)
    end

    def mark_transfers!
      update_all marked_as_transfer: true

      # Attempt to "auto match" and save a transfer if 2 transactions selected
      Account::Transfer.new(entries: all).save if all.count == 2
    end

    def bulk_update!(bulk_update_params)
      bulk_attributes = {
        date: bulk_update_params[:date],
        notes: bulk_update_params[:notes],
        entryable_attributes: {
          category_id: bulk_update_params[:category_id],
          merchant_id: bulk_update_params[:merchant_id]
        }.compact_blank
      }.compact_blank

      return 0 if bulk_attributes.blank?

      transaction do
        all.each do |entry|
          bulk_attributes[:entryable_attributes][:id] = entry.entryable_id if bulk_attributes[:entryable_attributes].present?
          entry.update! bulk_attributes
        end
      end

      all.size
    end

    def income_total(currency = "USD")
      total = without_transfers.account_transactions.includes(:entryable)
        .where("account_entries.amount <= 0")
                       .map { |e| e.amount_money.exchange_to(currency, date: e.date, fallback_rate: 0) }
                       .sum

      Money.new(total, currency)
    end

    def expense_total(currency = "USD")
      total = without_transfers.account_transactions.includes(:entryable)
                       .where("account_entries.amount > 0")
                       .map { |e| e.amount_money.exchange_to(currency, date: e.date, fallback_rate: 0) }
                       .sum

      Money.new(total, currency)
    end

    def search(params)
      query = all
      query = query.where("account_entries.name ILIKE ?", "%#{sanitize_sql_like(params[:search])}%") if params[:search].present?
      query = query.where("account_entries.date >= ?", params[:start_date]) if params[:start_date].present?
      query = query.where("account_entries.date <= ?", params[:end_date]) if params[:end_date].present?

      if params[:types].present?
        query = query.where(marked_as_transfer: false) unless params[:types].include?("transfer")

        if params[:types].include?("income") && !params[:types].include?("expense")
          query = query.where("account_entries.amount < 0")
        elsif params[:types].include?("expense") && !params[:types].include?("income")
          query = query.where("account_entries.amount >= 0")
        end
      end

      if params[:amount].present? && params[:amount_operator].present?
        case params[:amount_operator]
        when "equal"
          query = query.where("ABS(ABS(account_entries.amount) - ?) <= 0.01", params[:amount].to_f.abs)
        when "less"
          query = query.where("ABS(account_entries.amount) < ?", params[:amount].to_f.abs)
        when "greater"
          query = query.where("ABS(account_entries.amount) > ?", params[:amount].to_f.abs)
        end
      end

      if params[:accounts].present? || params[:account_ids].present?
        query = query.joins(:account)
      end

      query = query.where(accounts: { name: params[:accounts] }) if params[:accounts].present?
      query = query.where(accounts: { id: params[:account_ids] }) if params[:account_ids].present?

      # Search attributes on each entryable to further refine results
      entryable_ids = entryable_search(params)
      query = query.where(entryable_id: entryable_ids) unless entryable_ids.nil?

      query
    end

    private

      def entryable_search(params)
        entryable_ids = []
        entryable_search_performed = false

        Account::Entryable::TYPES.map(&:constantize).each do |entryable|
          next unless entryable.requires_search?(params)

          entryable_search_performed = true
          entryable_ids += entryable.search(params).pluck(:id)
        end

        return nil unless entryable_search_performed

        entryable_ids
      end
  end

  private

    def previous_entry
      @previous_entry ||= account
                            .entries
                            .where("date < ?", date)
                            .where("entryable_type = ?", entryable_type)
                            .order(date: :desc)
                            .first
    end

    def create_trend
      TimeSeries::Trend.new \
        current: amount_money,
        previous: previous_entry&.amount_money,
        favorable_direction: account.favorable_direction
    end
end
