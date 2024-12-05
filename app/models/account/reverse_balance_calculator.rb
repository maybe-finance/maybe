class Account::ReverseBalanceCalculator 
  def initialize(account)
    @account = account
  end

  def calculate
    entries = account.entries.order(:date).to_a

    prior_balance = account.balance

    Date.current.downto(entries.first&.date || Date.current).map do |date|
      entries_for_date = entries.select { |e| e.date == date }
      current_balance = calculate_balance(prior_balance, entries_for_date) 

      prior_balance = current_balance

      Account::Balance.new(
        account: account,
        date: date,
        balance: current_balance,
        currency: account.currency
      )
    end
  end

  private
    attr_reader :account

    def calculate_balance(prior_balance, entries)
      normalized_entries = entries.map do |entry|
        entry.amount = entry.amount_money.exchange_to(
          account.currency,
          date: entry.date,
          fallback_rate: 1
        ).amount

        entry.currency = account.currency
        entry
      end

      transactions = normalized_entries.select { |e| e.account_transaction? }
      valuation = normalized_entries.find { |e| e.account_valuation? }

      # Valuations take highest precedence
      return valuation.amount if valuation

      flows = transactions.sum(&:amount)
      flows *= -1 if account.liability?
      prior_balance + flows 
    end
end
