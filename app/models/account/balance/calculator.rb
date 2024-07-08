class Account::Balance::Calculator
  attr_reader :errors, :warnings

  def initialize(account, options = {})
    @errors = []
    @warnings = []
    @account = account
    @calc_start_date = calculate_sync_start(options[:calc_start_date])
  end

  def daily_balances
    @daily_balances ||= calculate_daily_balances
  end

  private

    attr_reader :calc_start_date, :account

    def calculate_sync_start(provided_start_date = nil)
      if account.balances.any?
        [ provided_start_date, account.effective_start_date ].compact.max
      else
        account.effective_start_date
      end
    end

    def calculate_daily_balances
      prior_balance = nil

      calculated_balances = (calc_start_date..Date.current).map do |date|
        valuation_entry = find_valuation_entry(date)

        if valuation_entry
          current_balance = valuation_entry.amount
        elsif prior_balance.nil?
          current_balance = implied_start_balance
        else
          txn_entries = syncable_transaction_entries.select { |e| e.date == date }
          txn_flows = transaction_flows(txn_entries)
          current_balance = prior_balance - txn_flows
        end

        prior_balance = current_balance

        { date:, balance: current_balance, currency: account.currency, updated_at: Time.current }
      end

      if account.foreign_currency?
        calculated_balances.concat(convert_balances_to_family_currency(calculated_balances))
      end

      calculated_balances
    end

    def syncable_entries
      @entries ||= account.entries.where("date >= ?", calc_start_date).to_a
    end

    def syncable_transaction_entries
      @syncable_transaction_entries ||= syncable_entries.select { |e| e.account_transaction? }
    end

    def find_valuation_entry(date)
      syncable_entries.find { |entry| entry.date == date && entry.account_valuation? }
    end

    def transaction_flows(transaction_entries)
      converted_entries = transaction_entries.map { |entry| convert_entry_to_account_currency(entry) }.compact
      flows = converted_entries.sum(&:amount)
      flows *= -1 if account.liability?
      flows
    end

    def convert_balances_to_family_currency(balances)
      rates = ExchangeRate.find_rates(
        from: account.currency,
        to: account.family.currency,
        start_date: calc_start_date
      ).to_a

      # Abort conversion if some required rates are missing
      if rates.length != balances.length
        @errors << :sync_message_missing_rates
        return []
      end

      balances.map do |balance|
        rate = rates.find { |r| r.date == balance[:date] }
        converted_balance = balance[:balance] * rate&.rate
        { date: balance[:date], balance: converted_balance, currency: account.family.currency, updated_at: Time.current }
      end
    end

    # Multi-currency accounts have transactions in many currencies
    def convert_entry_to_account_currency(entry)
      return entry if entry.currency == account.currency

      converted_entry = entry.dup

      rate = ExchangeRate.find_rate(from: entry.currency, to: account.currency, date: entry.date)

      unless rate
        @errors << :sync_message_missing_rates
        return nil
      end

      converted_entry.currency = account.currency
      converted_entry.amount = entry.amount * rate.rate
      converted_entry
    end

    def implied_start_balance
      transaction_entries = syncable_transaction_entries.select { |e| e.date > calc_start_date }
      account.balance.to_d + transaction_flows(transaction_entries)
    end
end
