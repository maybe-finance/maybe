# Resolves a Plaid security to an internal Security record, or nil
class PlaidAccount::SecurityResolver
  UnresolvablePlaidSecurityError = Class.new(StandardError)

  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  # Resolves an internal Security record for a given Plaid security ID
  def resolve(plaid_security_id:)
    response = @security_cache[plaid_security_id]
    return response if response.present?

    plaid_security = get_plaid_security(plaid_security_id)

    unless plaid_security
      report_unresolvable_security(plaid_security_id)
      return Response.new(security: nil, cash_equivalent?: false)
    end

    if brokerage_cash?(plaid_security)
      return Response.new(security: nil, cash_equivalent?: true)
    end

    if plaid_security.nil?
      report_unresolvable_security(plaid_security_id)
      response = Response.new(security: nil, cash_equivalent?: false)
    elsif brokerage_cash?(plaid_security)
      response = Response.new(security: nil, cash_equivalent?: true)
    else
      security = Security::Resolver.new(
        plaid_security["ticker_symbol"],
        exchange_operating_mic: plaid_security["market_identifier_code"]
      ).resolve

      response = Response.new(
        security: security,
        cash_equivalent?: cash_equivalent?(plaid_security)
      )
    end

    @security_cache[plaid_security_id] = response

    response
  end

  private
    attr_reader :plaid_account, :security_cache

    Response = Struct.new(:security, :cash_equivalent?, keyword_init: true)

    def securities
      plaid_account.raw_investments_payload["securities"] || []
    end

    # Tries to find security, or returns the "proxy security" (common with options contracts that have underlying securities)
    def get_plaid_security(plaid_security_id)
      security = securities.find { |s| s["security_id"] == plaid_security_id && s["ticker_symbol"].present? }

      return security if security.present?

      securities.find { |s| s["proxy_security_id"] == plaid_security_id }
    end

    # We ignore these.  Plaid calls these "holdings", but they are "brokerage cash" (treated separately in our system)
    def brokerage_cash?(plaid_security)
      [ "CUR:USD" ].include?(plaid_security["ticker_symbol"])
    end

    # These are valid holdings, but we use this designation to calculate the cash value of the account
    def cash_equivalent?(plaid_security)
      plaid_security["type"] == "cash" || plaid_security["is_cash_equivalent"] == true
    end

    def report_unresolvable_security(plaid_security_id)
      Sentry.capture_exception(UnresolvablePlaidSecurityError.new("Could not resolve Plaid security from provided data")) do |scope|
        scope.set_context("plaid_security", {
          plaid_security_id: plaid_security_id
        })
      end
    end
end
