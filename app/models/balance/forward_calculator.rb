class Balance::ForwardCalculator
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def calculate
    Rails.logger.tagged("Balance::ForwardCalculator") do
      calculate_balances
    end
  end

  private
    def calculate_balances
      # Derive initial balances from opening anchor
      opening_balance = account.opening_anchor_balance

      if cash_only_account?
        current_cash_balance = opening_balance
        current_non_cash_balance = 0
      elsif non_cash_account?
        current_cash_balance = 0
        current_non_cash_balance = opening_balance
      else # mixed_account?
        opening_holdings_value = holdings_value_for_date(account.opening_anchor_date)
        current_cash_balance = opening_balance - opening_holdings_value
        current_non_cash_balance = opening_holdings_value
      end

      next_cash_balance = nil
      next_non_cash_balance = nil

      @balances = []

      end_date = [ account.entries.order(:date).last&.date, account.holdings.order(:date).last&.date ].compact.max || Date.current

      account.opening_anchor_date.upto(end_date).each do |date|
        entries = sync_cache.get_entries(date)
        holdings = sync_cache.get_holdings(date)
        holdings_value = holdings.sum(&:amount)
        valuation = sync_cache.get_reconciliation_valuation(date)

        if valuation
          # Reconciliation valuation sets the total balance
          if cash_only_account?
            next_cash_balance = valuation.amount
            next_non_cash_balance = 0
          elsif non_cash_account?
            next_cash_balance = 0
            next_non_cash_balance = valuation.amount
          else # mixed_account?
            next_cash_balance = valuation.amount - holdings_value
            next_non_cash_balance = holdings_value
          end
        else
          # Apply transactions
          if cash_only_account?
            next_cash_balance = calculate_next_balance(current_cash_balance, entries, direction: :forward)
            next_non_cash_balance = 0
          elsif non_cash_account?
            # Special case: Loan accounts have transactions affect non-cash balance
            if account.accountable_type == "Loan"
              next_cash_balance = 0
              next_non_cash_balance = calculate_next_balance(current_non_cash_balance, entries, direction: :forward)
            else
              # Other non-cash accounts: transactions don't affect balance
              next_cash_balance = 0
              next_non_cash_balance = current_non_cash_balance
            end
          else # mixed_account?
            next_cash_balance = calculate_next_balance(current_cash_balance, entries, direction: :forward)
            next_non_cash_balance = holdings_value
          end
        end

        @balances << build_balance(date, next_cash_balance, next_non_cash_balance)

        current_cash_balance = next_cash_balance
        current_non_cash_balance = next_non_cash_balance
      end

      @balances
    end

    def sync_cache
      @sync_cache ||= Balance::SyncCache.new(account)
    end


    def holdings_value_for_date(date)
      holdings = sync_cache.get_holdings(date)
      holdings.sum(&:amount)
    end

    def build_balance(date, cash_balance, non_cash_balance)
      Balance.new(
        account_id: account.id,
        date: date,
        balance: non_cash_balance + cash_balance,
        cash_balance: cash_balance,
        currency: account.currency
      )
    end

    def calculate_next_balance(prior_balance, transactions, direction: :forward)
      flows = transactions.sum(&:amount)
      negated = direction == :forward ? account.asset? : account.liability?
      flows *= -1 if negated
      prior_balance + flows
    end

    # Accounts where entire balance is cash (transactions affect cash balance)
    def cash_only_account?
      account.accountable_type.in?([ "Depository", "CreditCard" ])
    end

    # Accounts where entire balance is non-cash (transactions don't affect balance)
    def non_cash_account?
      account.accountable_type.in?([ "Property", "Vehicle", "OtherAsset", "Loan", "OtherLiability" ])
    end

    # Mixed accounts that have both cash and non-cash components
    def mixed_account?
      account.accountable_type.in?([ "Investment", "Crypto" ])
    end
end
