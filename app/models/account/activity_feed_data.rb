# Data used to build the paginated feed of account "activity" (events like transfers, deposits, withdrawals, etc.)
# This data object is useful for avoiding N+1 queries and having an easy way to pass around the required data to the
# activity feed component in controllers and background jobs that refresh it.
class Account::ActivityFeedData
  attr_reader :account

  def initialize(account, entries)
    @account = account
    @entries = entries
  end

  # We read balances so we can show "start of day" -> "end of day" balances for each entry date group in the feed
  def balances
  end


  def transfers
    return [] unless has_transfers?

    @transfers ||= Transfer.where(inflow_transaction_id: transaction_ids).or(Transfer.where(outflow_transaction_id: transaction_ids))
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

      ExchangeRate.where(conditions, *params)
    end
  end

  private
    attr_reader :entries

    RequiredExchangeRate = Data.define(:date, :from, :to)

    def needs_exchange_rates?
      entries.any? { |entry| entry.currency != account.currency }
    end

    def required_exchange_rates
      multi_currency_entries = entries.select { |entry| entry.currency != account.currency }

      multi_currency_entries.map do |entry|
        RequiredExchangeRate.new(date: entry.date, from: entry.currency, to: account.currency)
      end.uniq
    end

    def has_transfers?
      entries.any? { |entry| entry.transaction? && entry.transaction.transfer? }
    end

    def transaction_ids
      entries.select { |entry| entry.transaction? }.pluck(:entryable_id)
    end
end
