# Resolves a Plaid security to an internal Security record, or nil
class PlaidAccount::Investments::SecurityResolver
  UnresolvablePlaidSecurityError = Class.new(StandardError)

  def initialize(plaid_account)
    @plaid_account = plaid_account
    @security_cache = {}
  end

  # Resolves an internal Security record for a given Plaid security ID
  def resolve(plaid_security_id:)
    response = @security_cache[plaid_security_id]
    return response if response.present?

    plaid_security = get_plaid_security(plaid_security_id)

    if plaid_security.nil?
      report_unresolvable_security(plaid_security_id)
      response = Response.new(security: nil, cash_equivalent?: false, brokerage_cash?: false)
    elsif brokerage_cash?(plaid_security)
      response = Response.new(security: nil, cash_equivalent?: true, brokerage_cash?: true)
    else
      security = Security::Resolver.new(
        plaid_security["ticker_symbol"],
        exchange_operating_mic: plaid_security["market_identifier_code"]
      ).resolve

      response = Response.new(
        security: security,
        cash_equivalent?: cash_equivalent?(plaid_security),
        brokerage_cash?: false
      )
    end

    @security_cache[plaid_security_id] = response

    response
  end

  private
    attr_reader :plaid_account, :security_cache

    Response = Struct.new(:security, :cash_equivalent?, :brokerage_cash?, keyword_init: true)

    def securities
      plaid_account.raw_investments_payload["securities"] || []
    end

    # Tries to find security, or returns the "proxy security" (common with options contracts that have underlying securities)
    def get_plaid_security(plaid_security_id)
      security = securities.find { |s| s["security_id"] == plaid_security_id && s["ticker_symbol"].present? }

      return security if security.present?

      securities.find { |s| s["proxy_security_id"] == plaid_security_id }
    end

    def report_unresolvable_security(plaid_security_id)
      Sentry.capture_exception(UnresolvablePlaidSecurityError.new("Could not resolve Plaid security from provided data")) do |scope|
        scope.set_context("plaid_security", {
          plaid_security_id: plaid_security_id
        })
      end
    end

    # Plaid treats "brokerage cash" differently than us.  Internally, Maybe treats "brokerage cash"
    # as "uninvested cash" (i.e. cash that doesn't have a corresponding Security and can be withdrawn).
    #
    # Plaid treats everything as a "holding" with a corresponding Security.  For example, "brokerage cash" (USD)
    # in Plaids data model would be represented as:
    #
    # - A Security with ticker `CUR:USD`
    # - A holding, linked to the `CUR:USD` Security, with an institution price of $1
    #
    # Internally, we store brokerage cash balance as `account.cash_balance`, NOT as a holding + security.
    # This allows us to properly build historical cash balances and holdings values separately and accurately.
    #
    # These help identify these "special case" securities for various calculations.
    #
    def known_plaid_brokerage_cash_tickers
      [ "CUR:USD" ]
    end

    def brokerage_cash?(plaid_security)
      return false unless plaid_security["ticker_symbol"].present?
      known_plaid_brokerage_cash_tickers.include?(plaid_security["ticker_symbol"])
    end

    def cash_equivalent?(plaid_security)
      return false unless plaid_security["type"].present?
      plaid_security["type"] == "cash" || plaid_security["is_cash_equivalent"] == true
    end
end
