class Account::Balance::Syncer
  def initialize(account, start_date: nil)
    @account = account
    @sync_start_date = calculate_sync_start_date(start_date)
  end

  def run
    daily_balances = calculate_daily_balances
    daily_balances += calculate_converted_balances(daily_balances) if account.currency != account.family.currency

    Account::Balance.transaction do
      upsert_balances!(daily_balances)
      purge_stale_balances!

      if daily_balances.any?
        account.reload
        account.update! balance: daily_balances.select { |db| db.currency == account.currency }.last&.balance
      end
    end
  rescue Money::ConversionError => e
    account.observe_missing_exchange_rates(from: e.from_currency, to: e.to_currency, dates: [ e.date ])
  end

  private

    attr_reader :sync_start_date, :account

    def upsert_balances!(balances)
      current_time = Time.now
      balances_to_upsert = balances.map do |balance|
        balance.attributes.slice("date", "balance", "currency").merge("updated_at" => current_time)
      end

      account.balances.upsert_all(balances_to_upsert, unique_by: %i[account_id date currency])
    end

    def purge_stale_balances!
      account.balances.delete_by("date < ?", account_start_date)
    end

    def calculate_balance_for_date(date, entries:, prior_balance:)
      valuation = entries.find { |e| e.date == date && e.account_valuation? }

      return valuation.amount if valuation
      return derived_sync_start_balance(entries) unless prior_balance

      entries = entries.select { |e| e.date == date }

      prior_balance - net_entry_flows(entries)
    end

    def calculate_daily_balances
      entries = account.entries.where("date >= ?", sync_start_date).to_a
      prior_balance = find_prior_balance

      (sync_start_date..Date.current).map do |date|
        current_balance = calculate_balance_for_date(date, entries:, prior_balance:)

        prior_balance = current_balance

        build_balance(date, current_balance)
      end
    end

    def calculate_converted_balances(balances)
      from_currency = account.currency
      to_currency = account.family.currency

      if ExchangeRate.exchange_rates_provider.nil?
        account.observe_missing_exchange_rate_provider
        return []
      end

      exchange_rates = ExchangeRate.find_rates from: from_currency,
                                               to: to_currency,
                                               start_date: sync_start_date

      missing_exchange_rates = balances.map(&:date) - exchange_rates.map(&:date)

      if missing_exchange_rates.any?
        account.observe_missing_exchange_rates(from: from_currency, to: to_currency, dates: missing_exchange_rates)
        return []
      end

      balances.map do |balance|
        exchange_rate = exchange_rates.find { |er| er.date == balance.date }
        build_balance(balance.date, exchange_rate.rate * balance.balance, to_currency)
      end
    end

    def build_balance(date, balance, currency = nil)
      account.balances.build \
        date: date,
        balance: balance,
        currency: currency || account.currency
    end

    def derived_sync_start_balance(entries)
      transactions_and_trades = entries.reject { |e| e.account_valuation? }.select { |e| e.date > sync_start_date }

      account.balance + net_entry_flows(transactions_and_trades)
    end

    def find_prior_balance
      account.balances.where("date < ?", sync_start_date).order(date: :desc).first&.balance
    end

    def net_entry_flows(entries, target_currency = account.currency)
      converted_entry_amounts = entries.map { |t| t.amount_money.exchange_to(target_currency, date: t.date) }

      flows = converted_entry_amounts.sum(&:amount)

      account.liability? ? flows * -1 : flows
    end

    def account_start_date
      @account_start_date ||= begin
                                oldest_entry_date = account.entries.chronological.first.try(:date)

                                return Date.current unless oldest_entry_date

                                oldest_entry_is_valuation = account.entries.account_valuations.where(date: oldest_entry_date).exists?

                                oldest_entry_date -= 1 unless oldest_entry_is_valuation
                                oldest_entry_date
                              end
    end

    def calculate_sync_start_date(provided_start_date)
      [ provided_start_date, account_start_date ].compact.max
    end
end
