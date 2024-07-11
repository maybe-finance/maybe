class Account::Balance::Syncer
  attr_reader :warnings

  def initialize(account, start_date: nil)
    @account = account
    @warnings = []
    @sync_start_date = calculate_sync_start_date(start_date)
  end

  def run
    daily_balances = calculate_daily_balances
    daily_balances += calculate_converted_balances(daily_balances) if account.currency != account.family.currency

    Account::Balance.transaction do
      upsert_balances!(daily_balances)
      purge_stale_balances!
    end
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

      transactions = entries.select { |e| e.date == date && e.account_transaction? }

      prior_balance - net_transaction_flows(transactions)
    end

    def calculate_daily_balances
      entries = account.entries.where("date >= ?", sync_start_date).to_a
      prior_balance = find_prior_balance

      daily_balances = (sync_start_date...Date.current).map do |date|
        current_balance = calculate_balance_for_date(date, entries:, prior_balance:)

        prior_balance = current_balance

        build_balance(date, current_balance)
      end

      # Last balance of series is always equal to account balance
      daily_balances << build_balance(Date.current, account.balance)
    end

    def calculate_converted_balances(balances)
      from_currency = account.currency
      to_currency = account.family.currency

      exchange_rates = ExchangeRate.find_rates from: from_currency,
                                               to: to_currency,
                                               start_date: sync_start_date

      balances.map do |balance|
        exchange_rate = exchange_rates.find { |er| er.date == balance.date }

        raise Money::ConversionError.new("missing exchange rate from #{from_currency} to #{to_currency} on date #{balance.date}") unless exchange_rate

        build_balance(balance.date, exchange_rate.rate * balance.balance, to_currency)
      end
    rescue Money::ConversionError
      @warnings << "missing exchange rates from #{from_currency} to #{to_currency}"
      []
    end

    def build_balance(date, balance, currency = nil)
      account.balances.build \
        date: date,
        balance: balance,
        currency: currency || account.currency
    end

    def derived_sync_start_balance(entries)
      transactions = entries.select { |e| e.account_transaction? && e.date > sync_start_date }

      account.balance + net_transaction_flows(transactions)
    end

    def find_prior_balance
      account.balances.where("date < ?", sync_start_date).order(date: :desc).first&.balance
    end

    def net_transaction_flows(transactions, target_currency = account.currency)
      converted_transaction_amounts = transactions.map { |t| t.amount_money.exchange_to(target_currency, date: t.date) }

      flows = converted_transaction_amounts.sum(&:amount)

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
