# Plaid Investment balances have a ton of edge cases.  This processor is responsible
# for deriving "brokerage cash" vs. "total value" based on Plaid's reported balances and holdings.
class PlaidAccount::InvestmentBalanceProcessor
  attr_reader :plaid_account

  def initialize(plaid_account)
    @plaid_account = plaid_account
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
        internal_security, plaid_security = get_security(h["security_id"])

        return false unless plaid_security.present?

        plaid_security_is_cash_equivalent = plaid_security["is_cash_equivalent"] || plaid_security["type"] == "cash"

        internal_security.present? && plaid_security_is_cash_equivalent
      end

      excludable_cash_holdings.sum { |h| h["quantity"] * h["institution_price"] }
    end

    def securities
      plaid_account.raw_investments_payload["securities"]
    end

    def get_security(plaid_security_id)
      plaid_security = securities.find { |s| s["security_id"] == plaid_security_id }

      return [ nil, nil ] if plaid_security.nil?

      plaid_security = if plaid_security["ticker_symbol"].present?
        plaid_security
      else
        securities.find { |s| s["security_id"] == plaid_security["proxy_security_id"] }
      end

      return [ nil, nil ] if plaid_security.nil? || plaid_security["ticker_symbol"].blank?
      return [ nil, plaid_security ] if plaid_security["ticker_symbol"] == "CUR:USD" # internally, we do not consider cash a security and track it separately

      operating_mic = plaid_security["market_identifier_code"]

      # Find any matching security
      security = Security.find_or_create_by!(
        ticker: plaid_security["ticker_symbol"]&.upcase,
        exchange_operating_mic: operating_mic&.upcase
      )

      [ security, plaid_security ]
    end
end
