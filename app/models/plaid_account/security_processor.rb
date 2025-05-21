# Resolves a Plaid security to an internal Security record, or nil
class PlaidAccount::SecurityProcessor
  def initialize(plaid_security_id, plaid_securities)
    @plaid_security_id = plaid_security_id
    @plaid_securities = plaid_securities
  end

  def process
  end

  private
    attr_reader :plaid_security_id, :plaid_securities

    # Tries to find security, or returns the "proxy security" (common with options contracts that have underlying securities)
    def plaid_security
      security = securities.find { |s| s["security_id"] == plaid_security_id && s["ticker_symbol"].present? }

      return security if security.present?

      securities.find { |s| s["proxy_security_id"] == plaid_security_id }
    end
end
