class Balance::BaseCalculator
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def calculate
    raise NotImplementedError, "Subclasses must implement this method"
  end

  private
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

    # Negative entries amount on an "asset" account means, "account value has increased"
    # Negative entries amount on a "liability" account means, "account debt has decreased"
    # Positive entries amount on an "asset" account means, "account value has decreased"
    # Positive entries amount on a "liability" account means, "account debt has increased"
    def signed_entry_flows(entries, direction: :forward)
      entry_flows = entries.sum(&:amount)
      negated = direction == :forward ? account.asset? : account.liability?
      entry_flows *= -1 if negated
      entry_flows
    end

    # "Cash balance" is the "liquid" component of balance (i.e. "cash in bank" or "brokerage cash" in investment accounts)
    # "Non-cash balance" is the "non-liquid" component of balance (i.e. "holdings" in investment accounts, "asset value" in property accounts)
    def transform_balance_components(balance_components, entries, direction: :forward)
      cash_balance = balance_components[:cash_balance]
      non_cash_balance = balance_components[:non_cash_balance]

      if cash_only_account?
        {
          cash_balance: cash_balance + signed_entry_flows(entries, direction: direction),
          non_cash_balance: non_cash_balance # no change
        }
      elsif non_cash_account?
        {
          cash_balance: cash_balance, # no change
          non_cash_balance: non_cash_balance + signed_entry_flows(entries, direction: direction)
        }
      else # mixed_account?
        {
          cash_balance: cash_balance + signed_entry_flows(entries, direction: direction),
          non_cash_balance: non_cash_balance
        }
      end
    end

    def calculate_next_balance(prior_balance, entries, direction: :forward)
      flows = entries.sum(&:amount)
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
