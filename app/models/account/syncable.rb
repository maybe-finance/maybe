module Account::Syncable
  extend ActiveSupport::Concern

  def sync_later(start_date = nil)
    AccountSyncJob.perform_later(self, start_date)
  end

  def sync(start_date = nil)
    update!(status: "syncing")

    if multi_currency? || foreign_currency?
      sync_exchange_rates
    end

    calculator = Account::Balance::Calculator.new(self, { calc_start_date: start_date })

    self.balances.upsert_all(calculator.daily_balances, unique_by: :index_account_balances_on_account_id_date_currency_unique)
    self.balances.where("date < ?", effective_start_date).delete_all
    new_balance = calculator.daily_balances.select { |b| b[:currency] == self.currency }.last[:balance]

    update! \
      status: "ok",
      last_sync_date: Date.current,
      balance: new_balance,
      sync_errors: calculator.errors,
      sync_warnings: calculator.warnings
  rescue => e
    update!(status: "error", sync_errors: [ :sync_message_unknown_error ])
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
    @effective_start_date ||= entries.order(:date).first.try(:date) || Date.current
  end

  # Finds all the rate pairs that are required to calculate balances for an account and syncs them
  def sync_exchange_rates
    rate_candidates = []

    if multi_currency?
      transactions_in_foreign_currency = self.entries.where.not(currency: self.currency).pluck(:currency, :date).uniq
      transactions_in_foreign_currency.each do |currency, date|
        rate_candidates << { date: date, from_currency: currency, to_currency: self.currency }
      end
    end

    if foreign_currency?
      (effective_start_date..Date.current).each do |date|
        rate_candidates << { date: date, from_currency: self.currency, to_currency: self.family.currency }
      end
    end

    return if rate_candidates.blank?

    existing_rates = ExchangeRate.where(
      from_currency: rate_candidates.map { |rc| rc[:from_currency] },
      to_currency: rate_candidates.map { |rc| rc[:to_currency] },
      date: rate_candidates.map { |rc| rc[:date] }
    ).pluck(:from_currency, :to_currency, :date)

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
