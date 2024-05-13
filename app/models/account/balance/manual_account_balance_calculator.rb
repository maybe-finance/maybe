class Account::Balance::ManualAccountBalanceCalculator
  def initialize(account)
    @account = account
    @calc_start_date = @account.effective_start_date
  end

  # Returns the current balance of a manual account in the account's currency
  def calculate_current_balance
    latest_valuation = normalized_latest_valuation
    latest_valuation_value = latest_valuation&.dig("value")
    latest_valuation_date = [ @account.effective_start_date, normalized_latest_valuation&.dig("date") ].compact.max
    net_transaction_flows = normalized_transactions(latest_valuation_date).sum { |t| t["amount"].to_d }
    net_transaction_flows *= -1 if @account.classification == "liability"
    start_balance = latest_valuation_value.present? ? latest_valuation_value : @account.start_balance.to_d

    start_balance - net_transaction_flows
  end

  private
    # For calculation, all transactions and valuations need to be normalized to the same currency (the account's primary currency)
    def normalize_entry_to_account_currency(entry, value_key)
      currency = entry.currency
      date = entry.date
      value = entry.send(value_key)

      if currency != @account.currency
        value = ExchangeRate.convert(value:, from: currency, to: @account.currency, date:)
        currency = @account.currency
      end

      entry.attributes.merge(value_key.to_s => value, "currency" => currency)
    end

    def normalize_entries_to_account_currency(entries, value_key)
      entries.map do |entry|
        normalize_entry_to_account_currency(entry, value_key)
      end
    end

    def normalized_latest_valuation
      valuation = @account.valuations.where("date <= ?", Date.current).order(date: :desc).select(:date, :value, :currency).first
      normalize_entry_to_account_currency(valuation, :value) unless valuation.nil?
    end

    def normalized_transactions(start_date)
      normalize_entries_to_account_currency(@account.transactions.where("date >= ?", start_date).where("date <= ?", Date.current).order(:date).select(:date, :amount, :currency), :amount)
    end
end
