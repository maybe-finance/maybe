class Account::BalanceCalculator
  def initialize(account)
    @account = account
  end

  def calculate(reverse: false, start_date: nil)
    cash_balances = reverse ? reverse_cash_balances : forward_cash_balances

    cash_balances.map do |balance|
      holdings_value = holdings.select { |h| h.date == balance.date }.sum(&:amount)
      balance.balance = balance.balance + holdings_value
      balance
    end
  end

  private
    attr_reader :account

    def oldest_date
      entries.first ? entries.first.date - 1.day : Date.current
    end

    def reverse_cash_balances
      prior_balance = account.cash_balance

      Date.current.downto(oldest_date).map do |date|
        entries_for_date = entries.select { |e| e.date == date }
        holdings_for_date = holdings.select { |h| h.date == date }

        valuation = entries_for_date.find { |e| e.account_valuation? }

        current_balance = if valuation
          # To get this to a cash valuation, we back out holdings value on day
          valuation.amount - holdings_for_date.sum(&:amount)
        else
          transactions = entries_for_date.select { |e| e.account_transaction? || e.account_trade? }

          calculate_balance(prior_balance, transactions)
        end

        balance_record = Account::Balance.new(
          account: account,
          date: date,
          balance: valuation ? current_balance : prior_balance,
          cash_balance: valuation ? current_balance : prior_balance,
          currency: account.currency
        )

        prior_balance = current_balance

        balance_record
      end
    end

    def forward_cash_balances
      prior_balance = 0
      current_balance = nil

      oldest_date.upto(Date.current).map do |date|
        entries_for_date = entries.select { |e| e.date == date }
        holdings_for_date = holdings.select { |h| h.date == date }

        valuation = entries_for_date.find { |e| e.account_valuation? }

        current_balance = if valuation
          # To get this to a cash valuation, we back out holdings value on day
          valuation.amount - holdings_for_date.sum(&:amount)
        else
          transactions = entries_for_date.select { |e| e.account_transaction? || e.account_trade? }

          calculate_balance(prior_balance, transactions, inverse: true)
        end

        balance_record = Account::Balance.new(
          account: account,
          date: date,
          balance: current_balance,
          cash_balance: current_balance,
          currency: account.currency
        )

        prior_balance = current_balance

        balance_record
      end
    end

    def entries
      @entries ||= @account.entries.order(:date).to_a.map do |e|
        converted_entry = e.dup
        converted_entry.amount = converted_entry.amount_money.exchange_to(
          account.currency,
          date: e.date,
          fallback_rate: 1
        ).amount
        converted_entry.currency = account.currency
        converted_entry
      end
    end

    def holdings
      @holdings ||= @account.holdings.to_a.map do |h|
        converted_holding = h.dup
        converted_holding.amount = converted_holding.amount_money.exchange_to(
          account.currency,
          date: h.date,
          fallback_rate: 1
        ).amount
        converted_holding.currency = account.currency
        converted_holding
      end
    end

    def calculate_balance(prior_balance, transactions, inverse: false)
      flows = transactions.sum(&:amount)
      negated = inverse ? account.asset? : account.liability?
      flows *= -1 if negated
      prior_balance + flows
    end
end
