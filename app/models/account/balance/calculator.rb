class Account::Balance::Calculator
  def initialize(account, sync_start_date)
    @account = account
    @sync_start_date = sync_start_date
  end

  def calculate(is_partial_sync: false)
    cached_entries = account.entries.where("date >= ?", sync_start_date).to_a
    sync_starting_balance = is_partial_sync ? find_start_balance_for_partial_sync : find_start_balance_for_full_sync(cached_entries)

    prior_balance = sync_starting_balance

    (sync_start_date..Date.current).map do |date|
      current_balance = calculate_balance_for_date(date, entries: cached_entries, prior_balance:)

      prior_balance = current_balance

      build_balance(date, current_balance)
    end
  end

  private
    attr_reader :account, :sync_start_date

    def find_start_balance_for_partial_sync
      account.balances.find_by(currency: account.currency, date: sync_start_date - 1.day).balance
    end

    def find_start_balance_for_full_sync(cached_entries)
      account.balance + net_entry_flows(cached_entries)
    end

    def calculate_balance_for_date(date, entries:, prior_balance:)
      valuation = entries.find { |e| e.date == date && e.account_valuation? }

      return valuation.amount if valuation

      entries = entries.select { |e| e.date == date }

      prior_balance - net_entry_flows(entries)
    end

    def net_entry_flows(entries, target_currency = account.currency)
      converted_entry_amounts = entries.map { |t| t.amount_money.exchange_to(target_currency, date: t.date) }

      flows = converted_entry_amounts.sum(&:amount)

      account.liability? ? flows * -1 : flows
    end

    def build_balance(date, balance, currency = nil)
      account.balances.build \
        date: date,
        balance: balance,
        currency: currency || account.currency
    end
end
