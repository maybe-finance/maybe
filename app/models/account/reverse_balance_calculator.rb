class Account::ReverseBalanceCalculator 
  def initialize(account)
    @account = account
  end

  def calculate
    entries = account.entries.order(:date).to_a.map do |e|
      e.amount = e.amount_money.exchange_to(
        account.currency,
        date: e.date,
        fallback_rate: 1
      ).amount
      e.currency = account.currency
      e
    end

    holdings = account.holdings.to_a.map do |h|
      h.amount = h.amount_money.exchange_to(
        account.currency,
        date: h.date,
        fallback_rate: 1
      ).amount
      h.currency = account.currency
      h
    end

    prior_balance = account.investment? ? account.investment.cash_balance : account.balance

    oldest_date = entries.first ? entries.first.date - 1.day : Date.current

    cash_balances = Date.current.downto(oldest_date).map do |date|
      entries_for_date = entries.select { |e| e.date == date }
      holdings_for_date = holdings.select { |h| h.date == date }

      valuation = entries_for_date.find { |e| e.account_valuation? }
      
      current_balance = if valuation 
        # To get this to a cash valuation, we back out holdings value on day
        valuation.amount - holdings_for_date.sum(&:amount)
      else
        transactions = entries_for_date.select { |e| e.account_transaction? }

        calculate_balance(prior_balance, transactions)
      end

      balance_record = Account::Balance.new(
        account: account,
        date: date,
        balance: valuation&.amount || prior_balance,
        currency: account.currency
      )

      prior_balance = current_balance

      balance_record
    end

    # Now, apply the daily holding values to the calculated cash balances
    cash_balances.map do |balance|
      holdings_value = holdings.select { |h| h.date == balance.date }.sum(&:amount)
      authoritative_holdings_value = balance.date == Date.current && account.investment? ? account.investment.holdings_balance : holdings_value
      balance.balance = balance.balance + holdings_value
      balance
    end
  end

  private
    attr_reader :account

    def calculate_balance(prior_balance, transactions)
      flows = transactions.sum(&:amount)
      flows *= -1 if account.liability?
      prior_balance + flows 
    end
end
