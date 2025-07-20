# Data used to build the paginated feed of account "activity" (events like transfers, deposits, withdrawals, etc.)
# This data object is useful for avoiding N+1 queries and having an easy way to pass around the required data to the
# activity feed component in controllers and background jobs that refresh it.
class Account::ActivityFeedData
  ActivityDateData = Data.define(:date, :entries, :balance_trend, :cash_balance_trend, :holdings_value_trend, :transfers)

  attr_reader :account, :entries

  def initialize(account, entries)
    @account = account
    @entries = entries.to_a
  end

  def entries_by_date
    @entries_by_date_objects ||= begin
      grouped_entries.map do |date, date_entries|
        ActivityDateData.new(
          date: date,
          entries: date_entries,
          balance_trend: balance_trend_for_date(date),
          cash_balance_trend: cash_balance_trend_for_date(date),
          holdings_value_trend: holdings_value_trend_for_date(date),
          transfers: transfers_for_date(date)
        )
      end
    end
  end

  private
    def balance_trend_for_date(date)
      build_trend_for_date(date, :balance_money)
    end

    def cash_balance_trend_for_date(date)
      date_entries = grouped_entries[date] || []
      has_valuation = date_entries.any?(&:valuation?)

      if has_valuation
        # When there's a valuation, calculate cash change from transaction entries only
        transactions = date_entries.select { |e| e.transaction? }
        cash_change = sum_entries_with_exchange_rates(transactions, date) * -1

        start_balance = start_balance_for_date(date)
        Trend.new(
          current: start_balance.cash_balance_money + cash_change,
          previous: start_balance.cash_balance_money
        )
      else
        build_trend_for_date(date, :cash_balance_money)
      end
    end

    def holdings_value_trend_for_date(date)
      date_entries = grouped_entries[date] || []
      has_valuation = date_entries.any?(&:valuation?)

      if has_valuation
        # When there's a valuation, calculate holdings change from trade entries only
        trades = date_entries.select { |e| e.trade? }
        holdings_change = sum_entries_with_exchange_rates(trades, date)

        start_balance = start_balance_for_date(date)
        start_holdings = start_balance.balance_money - start_balance.cash_balance_money
        Trend.new(
          current: start_holdings + holdings_change,
          previous: start_holdings
        )
      else
        build_trend_for_date(date) do |balance|
          balance.balance_money - balance.cash_balance_money
        end
      end
    end

    def transfers_for_date(date)
      date_entries = grouped_entries[date] || []
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

    def build_trend_for_date(date, method = nil)
      start_balance = start_balance_for_date(date)
      end_balance = end_balance_for_date(date)

      if block_given?
        Trend.new(
          current: yield(end_balance),
          previous: yield(start_balance)
        )
      else
        Trend.new(
          current: end_balance.send(method),
          previous: start_balance.send(method)
        )
      end
    end

    # Finds the balance on date, or the most recent balance before it ("last observation carried forward")
    def start_balance_for_date(date)
      @start_balance_for_date ||= {}
      @start_balance_for_date[date] ||= last_observed_balance_before_date(date.prev_day) || generate_fallback_balance(date)
    end

    # Finds the balance on date, or the most recent balance before it ("last observation carried forward")
    def end_balance_for_date(date)
      @end_balance_for_date ||= {}
      @end_balance_for_date[date] ||= last_observed_balance_before_date(date) || generate_fallback_balance(date)
    end

    RequiredExchangeRate = Data.define(:date, :from, :to)

    def grouped_entries
      @grouped_entries ||= entries.group_by(&:date)
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

        # Use ActiveRecord's or chain for better performance
        conditions = rate_requirements.map do |req|
          ExchangeRate.where(date: req.date, from_currency: req.from, to_currency: req.to)
        end.reduce(:or)

        conditions.to_a
      end
    end

    def exchange_rate_for(date, from_currency, to_currency)
      return 1.0 if from_currency == to_currency

      rate = exchange_rates.find { |r| r.date == date && r.from_currency == from_currency && r.to_currency == to_currency }
      rate&.rate || 1.0  # Fallback to 1:1 if no rate found
    end

    def sum_entries_with_exchange_rates(entries, date)
      return Money.new(0, account.currency) if entries.empty?

      entries.sum do |entry|
        amount = entry.amount_money
        if entry.currency != account.currency
          rate = exchange_rate_for(date, entry.currency, account.currency)
          Money.new(amount.amount * rate, account.currency)
        else
          amount
        end
      end
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

    def transaction_ids
      entries.select { |entry| entry.transaction? }.map(&:entryable_id)
    end

    def transfers
      return [] if entries.select { |e| e.transaction? && e.transaction.transfer? }.empty?
      return [] if transaction_ids.empty?

      @transfers ||= Transfer.where(inflow_transaction_id: transaction_ids).or(Transfer.where(outflow_transaction_id: transaction_ids)).to_a
    end

    # Use binary search since balances are sorted by date
    def last_observed_balance_before_date(date)
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
