class Account::BalanceCalculator
    def initialize(account)
      @account = account
    end

    def daily_balances(start_date = nil)
      calc_start_date = [ start_date, @account.effective_start_date ].compact.max

      valuations = @account.valuations.where("date >= ?", calc_start_date).order(:date).select(:date, :value, :currency)
      transactions = @account.transactions.where("date > ?", calc_start_date).order(:date).select(:date, :amount, :currency)
      oldest_entry = [ valuations.first, transactions.first ].compact.min_by(&:date)

      net_transaction_flows = transactions.sum(&:amount)
      net_transaction_flows *= -1 if @account.classification == "liability"
      implied_start_balance = oldest_entry.is_a?(Valuation) ? oldest_entry.value : @account.balance + net_transaction_flows

      prior_balance = implied_start_balance
      calculated_balances = ((calc_start_date + 1.day)...Date.current).map do |date|
        valuation = valuations.find { |v| v.date == date }

        if valuation
            current_balance = valuation.value
        else
            current_day_net_transaction_flows = transactions.select { |t| t.date == date }.sum(&:amount)
            current_day_net_transaction_flows *= -1 if @account.classification == "liability"
            current_balance = prior_balance - current_day_net_transaction_flows
        end

        prior_balance = current_balance

        { date: date, balance: current_balance, updated_at: Time.current }
      end

      [
        { date: calc_start_date, balance: implied_start_balance, updated_at: Time.current },
        *calculated_balances,
        { date: Date.current, balance: @account.balance, updated_at: Time.current } # Last balance must always match "source of truth"
      ]
    end
end
