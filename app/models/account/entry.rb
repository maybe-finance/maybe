class Account::Entry < ApplicationRecord
  include Monetizable

  monetize :amount

  belongs_to :account
  belongs_to :transfer, optional: true
  belongs_to :import, optional: true

  delegated_type :entryable, types: Account::Entryable::TYPES, dependent: :destroy
  accepts_nested_attributes_for :entryable

  validates :date, :name, :amount, :currency, presence: true
  validates :date, uniqueness: { scope: [ :account_id, :entryable_type ] }, if: -> { account_valuation? }
  validates :date, comparison: { greater_than: -> { min_supported_date } }

  scope :chronological, -> {
    order(
      date: :asc,
      Arel.sql("CASE WHEN account_entries.entryable_type = 'Account::Valuation' THEN 1 ELSE 0 END") => :asc,
      created_at: :asc
    )
  }

  scope :reverse_chronological, -> {
    order(
      date: :desc,
      Arel.sql("CASE WHEN account_entries.entryable_type = 'Account::Valuation' THEN 1 ELSE 0 END") => :desc,
      created_at: :desc
    )
  }

  # All non-transfer entries, rejected transfers, and the outflow of a loan payment transfer are incomes/expenses
  scope :incomes_and_expenses, -> {
    joins("INNER JOIN account_transactions ON account_transactions.id = account_entries.entryable_id AND account_entries.entryable_type = 'Account::Transaction'")
    .joins("LEFT JOIN transfers ON transfers.inflow_transaction_id = account_transactions.id OR transfers.outflow_transaction_id = account_transactions.id")
    .joins("LEFT JOIN account_transactions inflow_txns ON inflow_txns.id = transfers.inflow_transaction_id")
    .joins("LEFT JOIN account_entries inflow_entries ON inflow_entries.entryable_id = inflow_txns.id AND inflow_entries.entryable_type = 'Account::Transaction'")
    .joins("LEFT JOIN accounts inflow_accounts ON inflow_accounts.id = inflow_entries.account_id")
    .where("transfers.id IS NULL OR transfers.status = 'rejected' OR (account_entries.amount > 0 AND inflow_accounts.accountable_type = 'Loan')")
  }

  scope :incomes, -> {
    incomes_and_expenses.where("account_entries.amount <= 0")
  }

  scope :expenses, -> {
    incomes_and_expenses.where("account_entries.amount > 0")
  }

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
    sync_start_date = [ date_previously_was, date ].compact.min unless destroyed?
    account.sync_later(start_date: sync_start_date)
  end

  def entryable_name_short
    entryable_type.demodulize.underscore
  end

  def balance_trend(entries, balances)
    Account::BalanceTrendCalculator.new(self, entries, balances).trend
  end

  def display_name
    enriched_name.presence || name
  end

  def transfer_match_candidates
    candidates_scope = account.transfer_match_candidates

    candidates_scope = if amount.negative?
      candidates_scope.where("inflow_candidates.entryable_id = ?", entryable_id)
    else
      candidates_scope.where("outflow_candidates.entryable_id = ?", entryable_id)
    end

    candidates_scope.map do |pm|
      Transfer.new(
        inflow_transaction_id: pm.inflow_transaction_id,
        outflow_transaction_id: pm.outflow_transaction_id,
      )
    end
  end

  class << self
    def search(params)
      Account::EntrySearch.new(params).build_query(all)
    end

    # arbitrary cutoff date to avoid expensive sync operations
    def min_supported_date
      30.years.ago.to_date
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

    def income_total(currency = "USD", start_date: nil, end_date: nil)
      total = incomes.where(date: start_date..end_date)
                       .map { |e| e.amount_money.exchange_to(currency, date: e.date, fallback_rate: 0) }
                       .sum

      Money.new(total, currency)
    end

    def expense_total(currency = "USD", start_date: nil, end_date: nil)
      total = expenses.where(date: start_date..end_date)
                       .map { |e| e.amount_money.exchange_to(currency, date: e.date, fallback_rate: 0) }
                       .sum

      Money.new(total, currency)
    end
  end
end
