# Data used to build the paginated feed of account "activity" (events like transfers, deposits, withdrawals, etc.)
# This data object is useful for avoiding N+1 queries and having an easy way to pass around the required data to the
# activity feed component in controllers and background jobs that refresh it.
class Account::ActivityFeedData
  ActivityDateData = Data.define(:date, :entries, :balance, :transfers)

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
          balance: balance_for_date(date),
          transfers: transfers_for_date(date)
        )
      end
    end
  end

  private
    def balance_for_date(date)
      balances_by_date[date]
    end

    def transfers_for_date(date)
      transfers_by_date[date] || []
    end

    def grouped_entries
      @grouped_entries ||= entries.group_by(&:date)
    end

    def balances_by_date
      @balances_by_date ||= begin
        return {} if entries.empty?

        dates = grouped_entries.keys
        account.balances
          .where(date: dates, currency: account.currency)
          .index_by(&:date)
      end
    end

    def transfers_by_date
      @transfers_by_date ||= begin
        return {} if transaction_ids.empty?

        transfers = Transfer
          .where(inflow_transaction_id: transaction_ids)
          .or(Transfer.where(outflow_transaction_id: transaction_ids))
          .to_a

        # Group transfers by the date of their transaction entries
        result = Hash.new { |h, k| h[k] = [] }

        entries.each do |entry|
          next unless entry.transaction? && transaction_ids.include?(entry.entryable_id)

          transfers.each do |transfer|
            if transfer.inflow_transaction_id == entry.entryable_id ||
               transfer.outflow_transaction_id == entry.entryable_id
              result[entry.date] << transfer
            end
          end
        end

        # Remove duplicates
        result.transform_values(&:uniq)
      end
    end

    def transaction_ids
      @transaction_ids ||= entries
        .select(&:transaction?)
        .map(&:entryable_id)
        .compact
    end
end
