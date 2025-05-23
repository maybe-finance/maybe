# Plaid Investment balances have a ton of edge cases.  This processor is responsible
# for deriving "brokerage cash" vs. "total value" based on Plaid's reported balances and holdings.
class PlaidAccount::Investments::BalanceCalculator
  NegativeCashBalanceError = Class.new(StandardError)
  NegativeTotalValueError = Class.new(StandardError)

  def initialize(plaid_account, security_resolver:)
    @plaid_account = plaid_account
    @security_resolver = security_resolver
  end

  def balance
    total_value = total_investment_account_value

    if total_value.negative?
      Sentry.capture_exception(
        NegativeTotalValueError.new("Total value is negative for plaid investment account"),
        level: :warning
      )
    end

    total_value
  end

  # Plaid considers "brokerage cash" and "cash equivalent holdings" to all be part of "cash balance"
  #
  # Internally, we DO NOT.  Maybe clearly distinguishes between "brokerage cash" vs. "holdings (i.e. invested cash)"
  # For this reason, we must manually calculate the cash balance based on "total value" and "holdings value"
  # See PlaidAccount::Investments::SecurityResolver for more details.
  def cash_balance
    cash_balance = calculate_investment_brokerage_cash

    if cash_balance.negative?
      Sentry.capture_exception(
        NegativeCashBalanceError.new("Cash balance is negative for plaid investment account"),
        level: :warning
      )
    end

    cash_balance
  end

  private
    attr_reader :plaid_account, :security_resolver

    def holdings
      plaid_account.raw_investments_payload["holdings"] || []
    end

    def calculate_investment_brokerage_cash
      total_investment_account_value - true_holdings_value
    end

    # This is our source of truth.  We assume Plaid's `current_balance` reporting is 100% accurate
    # Plaid guarantees `current_balance` AND/OR `available_balance` is always present, and based on the docs,
    # `current_balance` should represent "total account value".
    def total_investment_account_value
      plaid_account.current_balance || plaid_account.available_balance
    end

    # Plaid holdings summed up, LESS "brokerage cash" holdings (that we've manually identified)
    def true_holdings_value
      # True holdings are holdings *less* Plaid's "pseudo-securities" (e.g. `CUR:USD` brokerage cash "holding")
      true_holdings = holdings.reject do |h|
        security = security_resolver.resolve(plaid_security_id: h["security_id"])
        security.brokerage_cash?
      end

      true_holdings.sum { |h| h["quantity"] * h["institution_price"] }
    end
end
