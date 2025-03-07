class Account::Balance::BaseCalculator
  attr_reader :account

  def initialize(account)
    @account = account
  end

  private
    CashBalance = Data.define(:date, :balance)

    def sync_cache
      @sync_cache ||= Account::Balance::SyncCache.new(account)
    end

    def build_balance(amount, date)
      Account::Balance.new(
        account: account,
        date: date,
        balance: amount,
        cash_balance: amount,
        currency: account.currency
      )
    end

    def calculate_next_balance(prior_balance, transactions, direction: :forward)
      flows = transactions.sum(&:amount)
      negated = direction == :forward ? account.asset? : account.liability?
      flows *= -1 if negated
      prior_balance + flows
    end
end
