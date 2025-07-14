# Takes a known "current" balance and its components, applies a list of "entries" against
# these components, and returns the new balance and its components
class Balance::Transformer
  InvalidAccountTypeError = Class.new(StandardError)

  def initialize(account, transformation_direction: :forward)
    @account = account
    @transformation_direction = transformation_direction
  end

  # Valuations are a "snapshot" mechanism so we can say, "On X date, the account value/debt was $Y"
  def apply_valuation(valuation, non_cash_valuation: nil)
    non_cash_amount = non_cash_valuation || 0
    total_amount = valuation.amount # this is the "snapshot" amount (i.e. "total account value/debt")

    Balance.new(
      cash_balance: affects_cash_balance? ? total_amount - non_cash_amount : 0,
      non_cash_balance: non_cash_account? ? total_amount : non_cash_amount
    )
  end

  def transform(cash_balance:, non_cash_balance:, entries: [])
    entry_flow = signed_entry_flows(entries)

    Balance.new(
      cash_balance: cash_balance + (affects_cash_balance? ? entry_flow : 0),
      non_cash_balance: non_cash_balance + (affects_non_cash_balance? ? entry_flow : 0)
    )
  end

  private
    Balance = Data.define(:cash_balance, :non_cash_balance)
    attr_reader :account, :transformation_direction

    def affects_cash_balance?
      cash_only_account? || mixed_account?
    end

    def affects_non_cash_balance?
      non_cash_account? && account.accountable_type == "Loan"
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
