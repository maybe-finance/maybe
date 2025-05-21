module PlaidAccount::Securitizable
  extend ActiveSupport::Concern

  # TODO
  def get_security(plaid_security_id)
    plaid_security = get_plaid_security(plaid_security_id)



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



  private
    def securities
      @securities ||= plaid_account.raw_investments_payload["securities"] || []
    end

    # These are the tickers that Plaid considers a "security", but we do not (mostly cash-like tickers)
    #
    # For example, "CUR:USD" is what Plaid uses for the "Cash Holding" and represents brokerage cash sitting
    # in the brokerage account.  Internally, we treat brokerage cash as a separate concept.  It is NOT a holding
    # in the Maybe app (although in the UI, we show it next to other holdings).
    def ignored_plaid_security_tickers
      [ "CUR:USD" ]
    end
end
