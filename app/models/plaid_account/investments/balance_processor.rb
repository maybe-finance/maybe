# Plaid Investment balances have a ton of edge cases.  This processor is responsible
# for deriving "brokerage cash" vs. "total value" based on Plaid's reported balances and holdings.
class PlaidAccount::Investments::BalanceProcessor
  attr_reader :plaid_account, :security_resolver

  def initialize(plaid_account, security_resolver:)
    @plaid_account = plaid_account
    @security_resolver = security_resolver
  end

  def balance
    plaid_account.current_balance || plaid_account.available_balance
  end

  # Plaid considers "brokerage cash" and "cash equivalent holdings" to all be part of "cash balance"
  # Internally, we DO NOT.
  # Maybe clearly distinguishes between "brokerage cash" vs. "holdings (i.e. invested cash)"
  # For this reason, we must back out cash + cash equivalent holdings from the reported cash balance to avoid double counting
  def cash_balance
    plaid_account.available_balance - excludable_cash_holdings_value
  end

  private
    def holdings
      plaid_account.raw_investments_payload["holdings"]
    end

    def excludable_cash_holdings_value
      excludable_cash_holdings = holdings.select do |h|
        response = security_resolver.resolve(plaid_security_id: h["security_id"])
        response.security.present? && response.cash_equivalent?
      end

      excludable_cash_holdings.sum { |h| h["quantity"] * h["institution_price"] }
    end
end
