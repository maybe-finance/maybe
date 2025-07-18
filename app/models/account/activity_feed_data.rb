# Data used to build the paginated feed of account "activity" (events like transfers, deposits, withdrawals, etc.)
# This data object is useful for avoiding N+1 queries and having an easy way to pass around the required data to the
# activity feed component in controllers and background jobs that refresh it.
class Account::ActivityFeedData
  attr_reader :account, :entries

  def initialize(account, entries)
    @account = account
    @entries = entries.to_a
  end

  def trend_for_date(date)
    start_balance = start_balance_for_date(date)
    end_balance = end_balance_for_date(date)

    Trend.new(
      current: end_balance.balance_money,
      previous: start_balance.balance_money
    )
  end

  def transfers_for_date(date)
    date_entries = entries_by_date[date] || []
    return [] if date_entries.empty?

    date_transaction_ids = date_entries.select(&:transaction?).map(&:entryable_id)
    return [] if date_transaction_ids.empty?

    # Convert to Set for O(1) lookups
    date_transaction_id_set = Set.new(date_transaction_ids)

    transfers.select { |txfr|
      date_transaction_id_set.include?(txfr.inflow_transaction_id) ||
      date_transaction_id_set.include?(txfr.outflow_transaction_id)
    }
  end

  def exchange_rates_for_date(date)
    exchange_rates.select { |rate| rate.date == date }
  end

  private
    # Finds the balance on date, or the most recent balance before it ("last observation carried forward")
    def start_balance_for_date(date)
      locf_balance_for_date(date.prev_day) || generate_fallback_balance(date)
    end

    # Finds the balance on date, or the most recent balance before it ("last observation carried forward")
    def end_balance_for_date(date)
      locf_balance_for_date(date) || generate_fallback_balance(date)
    end

    RequiredExchangeRate = Data.define(:date, :from, :to)

    def entries_by_date
      @entries_by_date ||= entries.group_by(&:date)
    end

    # We read balances so we can show "start of day" -> "end of day" balances for each entry date group in the feed
    def balances
      @balances ||= begin
        return [] if entries.empty?

        min_date = entries.min_by(&:date).date.prev_day
        max_date = entries.max_by(&:date).date

        account.balances.where(date: min_date..max_date, currency: account.currency).order(:date).to_a
      end
    end

    def needs_exchange_rates?
      entries.any? { |entry| entry.currency != account.currency }
    end

    def required_exchange_rates
      multi_currency_entries = entries.select { |entry| entry.currency != account.currency }

      multi_currency_entries.map do |entry|
        RequiredExchangeRate.new(date: entry.date, from: entry.currency, to: account.currency)
      end.uniq
    end

    # If the account has entries denominated in a different currency than the main account, we attach necessary
    # exchange rates required to "roll up" the entry group balance into the normal account currency.
    def exchange_rates
      return [] unless needs_exchange_rates?

      @exchange_rates ||= begin
        rate_requirements = required_exchange_rates
        return [] if rate_requirements.empty?

        # Build a single SQL query with all date/currency pairs
        conditions = rate_requirements.map do |req|
          "(date = ? AND from_currency = ? AND to_currency = ?)"
        end.join(" OR ")

        # Flatten the parameters array in the same order
        params = rate_requirements.flat_map do |req|
          [ req.date, req.from, req.to ]
        end

        ExchangeRate.where(conditions, *params).to_a
      end
    end

    def transaction_ids
      entries.select { |entry| entry.transaction? }.map(&:entryable_id)
    end

    def has_transfers?
      entries.any? { |entry| entry.transaction? && entry.transaction.transfer? }
    end

    def transfers
      return [] unless has_transfers?

      @transfers ||= Transfer.where(inflow_transaction_id: transaction_ids).or(Transfer.where(outflow_transaction_id: transaction_ids)).to_a
    end

    # Use binary search since balances are sorted by date
    def locf_balance_for_date(date)
      idx = balances.bsearch_index { |b| b.date > date }

      if idx
        idx > 0 ? balances[idx - 1] : nil
      else
        balances.last
      end
    end

    def generate_fallback_balance(date)
      Balance.new(
        account: account,
        date: date,
        balance: 0,
        currency: account.currency
      )
    end
end
