module Account::Syncable
  extend ActiveSupport::Concern

  included do
    include AASM

    enum :status, { ok: "ok", syncing: "syncing", error: "error" }, validate: true

    def some_syncing?
      exists?(status: "syncing")
    end

    aasm column: :status, enum: true do
      state :ok, initial: true
      state :syncing
      state :error

      event :sync do
        transitions from: :ok, to: :syncing, if: :can_sync?
        transitions from: :ok, to: :error, if: :can_sync?
        after { |start_date| start_sync(start_date) }
        error { sync_fails }
      end

      event :sync_fails do
        transitions to: :error
      end

      event :sync_succeeds do
        transitions to: :ok
      end
    end
  end

  def sync_later(start_date = nil)
    AccountSyncJob.perform_later(self, start_date)
  end

  def start_sync(start_date = nil)
    sync_exchange_rates

    calc_start_date = start_date - 1.day if start_date.present? && self.balance_on(start_date - 1.day).present?

    calculator = Account::Balance::Calculator.new(self, { calc_start_date: })
    calculator.calculate
    self.balances.upsert_all(calculator.daily_balances, unique_by: :index_account_balances_on_account_id_date_currency_unique)
    self.balances.where("date < ?", effective_start_date).delete_all
    new_balance = calculator.daily_balances.select { |b| b[:currency] == self.currency }.last[:balance]

    update!(last_sync_date: Date.today, balance: new_balance, sync_errors: calculator.errors, sync_warnings: calculator.warnings)
    sync_succeeds
  rescue => e
    sync_fails
    update!(sync_errors: [ :sync_message_unknown_error ])
    logger.error("Failed to sync account #{id}: #{e.message}")
  end

  def can_sync?
    # Skip account sync if account is not active or the sync process is already running
    return false unless is_active
    return false if syncing?
    # If last_sync_date is blank (i.e. the account has never been synced before) allow syncing
    return true if last_sync_date.blank?

    # If last_sync_date is not today, allow syncing
    last_sync_date != Date.today
  end

  # The earliest date we can calculate a balance for
  def effective_start_date
    first_valuation_date = self.valuations.order(:date).pluck(:date).first
    first_transaction_date = self.transactions.order(:date).pluck(:date).first

    [ first_valuation_date, first_transaction_date&.prev_day ].compact.min || Date.current
  end

  # Finds all the rate pairs that are required to calculate balances for an account and syncs them
  def sync_exchange_rates
    rate_candidates = []

    if multi_currency?
      transactions_in_foreign_currency = self.transactions.where.not(currency: self.currency).pluck(:currency, :date).uniq
      transactions_in_foreign_currency.each do |currency, date|
        rate_candidates << { date: date, from_currency: currency, to_currency: self.currency }
      end
    end

    if foreign_currency?
      (effective_start_date..Date.current).each do |date|
        rate_candidates << { date: date, from_currency: self.currency, to_currency: self.family.currency }
      end
    end

    existing_rates = ExchangeRate.where(
      base_currency: rate_candidates.map { |rc| rc[:from_currency] },
      converted_currency: rate_candidates.map { |rc| rc[:to_currency] },
      date: rate_candidates.map { |rc| rc[:date] }
    ).pluck(:base_currency, :converted_currency, :date)

    # Convert to a set for faster lookup
    existing_rates_set = existing_rates.map { |er| [ er[0], er[1], er[2].to_s ] }.to_set

    rate_candidates.each do |rate_candidate|
      rc_from = rate_candidate[:from_currency]
      rc_to = rate_candidate[:to_currency]
      rc_date = rate_candidate[:date]

      next if existing_rates_set.include?([ rc_from, rc_to, rc_date.to_s ])

      logger.info "Fetching exchange rate from provider for account #{self.name}: #{self.id} (#{rc_from} to #{rc_to} on #{rc_date})"
      ExchangeRate.find_rate_or_fetch from: rc_from, to: rc_to, date: rc_date
    end

    nil
  end
end
