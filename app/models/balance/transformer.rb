# Takes a known "current" balance and its components, applies a list of "entries" against
# these components, and returns the new balance and its components
class Balance::Transformer
  InvalidAccountTypeError = Class.new(StandardError)

  def initialize(account, transformation_direction: :forward)
    @account = account
    @transformation_direction = transformation_direction
  end

  # Valuations are a "snapshot" mechanism so we can say, "On X date, the account value/debt was $Y"
  def set_absolute_balance(total_balance:, holdings_value: nil)
    non_cash_balance = account.balance_type == :investment ? holdings_value : 0

    Balance.new(
      cash_balance: entries_affect_cash_balance? ? total_balance - non_cash_balance : 0,
      non_cash_balance: account.balance_type == :non_cash ? total_balance : non_cash_balance
    )
  end

  def transform_balance(start_cash_balance:, start_non_cash_balance:, today_entries: [], today_holdings_value: nil)
    entry_flow = signed_entry_flows(today_entries)

    effective_non_cash_balance = account.balance_type == :investment ? today_holdings_value : start_non_cash_balance

    Balance.new(
      cash_balance: start_cash_balance + (entries_affect_cash_balance? ? entry_flow : 0),
      non_cash_balance: effective_non_cash_balance + (entries_affect_non_cash_balance? ? entry_flow : 0)
    )
  end

  private
    Balance = Data.define(:cash_balance, :non_cash_balance)

    attr_reader :account, :transformation_direction

    def entries_affect_cash_balance?
      account.balance_type.in?([ :cash, :investment ])
    end

    # Loans are special cases and are the only non-cash accounts where entries (like a loan payment) affects the non-cash balance
    def entries_affect_non_cash_balance?
      account.balance_type == :non_cash && account.accountable_type == "Loan"
    end

    # Negative entries amount on an "asset" account means, "account value has increased"
    # Negative entries amount on a "liability" account means, "account debt has decreased"
    # Positive entries amount on an "asset" account means, "account value has decreased"
    # Positive entries amount on a "liability" account means, "account debt has increased"
    def signed_entry_flows(entries)
      entry_flows = entries.sum(&:amount)
      negated = transformation_direction == :forward ? account.asset? : account.liability?
      entry_flows *= -1 if negated
      entry_flows
    end
end
