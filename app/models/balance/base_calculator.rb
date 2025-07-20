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

    def derive_cash_balance_on_date_from_total(total_balance:, date:)
      if account.balance_type == :investment
        total_balance - holdings_value_for_date(date)
      elsif account.balance_type == :cash
        total_balance
      else
        0
      end
    end

    def derive_cash_balance(cash_balance, date)
      entries = sync_cache.get_entries(date)

      if account.balance_type == :non_cash
        0
      else
        cash_balance + signed_entry_flows(entries)
      end
    end

    def derive_non_cash_balance(non_cash_balance, date, direction: :forward)
      entries = sync_cache.get_entries(date)
      # Loans are a special case (loan payment reducing principal, which is non-cash)
      if account.balance_type == :non_cash && account.accountable_type == "Loan"
        non_cash_balance + signed_entry_flows(entries)
      elsif account.balance_type == :investment
        # For reverse calculations, we need the previous day's holdings
        target_date = direction == :forward ? date : date.prev_day
        holdings_value_for_date(target_date)
      else
        non_cash_balance
      end
    end

    def signed_entry_flows(entries)
      raise NotImplementedError, "Directional calculators must implement this method"
    end

    def build_balance(date:, cash_balance:, non_cash_balance:)
      Balance.new(
        account_id: account.id,
        date: date,
        balance: non_cash_balance + cash_balance,
        cash_balance: cash_balance,
        currency: account.currency
      )
    end
end
