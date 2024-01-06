class SyncPlaidHoldingsJob

  def perform(item_id)
    connection = Connection.find_by(source: 'plaid', item_id: item_id)

    return if connection.nil? or connection.status == 'error' or !connection.has_investments?

    access_token = connection.access_token
    accounts = connection.accounts

    # Create a hash of account ids with matching source ids
    account_ids = accounts.map { |account| [account.source_id, account.id] }.to_h

    holdings_request = Plaid::InvestmentsHoldingsGetRequest.new({
      access_token: access_token
    })

    # Rescue status code 400
    begin
      holdings_response = $plaid_api_client.investments_holdings_get(holdings_request)
    rescue Plaid::ApiError => e
      if e.code == 400
        if JSON.parse(e.response_body)['error_code'] != 'PRODUCTS_NOT_SUPPORTED' or JSON.parse(e.response_body)['error_code'] != 'NO_INVESTMENT_ACCOUNTS'
          # Update connection status to error and store the respoonse body in the error_message column
          connection.update(status: 'error', error: JSON.parse(e.response_body))
        end
        return
      end
    end

    # Process all securities first
    securities = holdings_response.securities

    # upsert_all securities
    all_securities = []

    securities.each do |security|
      all_securities << {
        source_id: security.security_id,
        name: security.name,
        symbol: security.ticker_symbol,
        source: 'plaid',
        source_type: security.type,
        currency_code: security.iso_currency_code,
        cusip: security.cusip,
        isin: security.isin
      }
    end

    Security.upsert_all(all_securities, unique_by: :index_securities_on_source_id)

    # Process all holdings
    holdings = holdings_response.holdings

    # upsert_all holdings
    all_holdings = []

    holdings.each do |holding|
      next if account_ids[holding.account_id].nil?
      next if holding.quantity <= 0

      all_holdings << {
        account_id: account_ids[holding.account_id],
        security_id: Security.find_by(source_id: holding.security_id).id,
        quantity: holding.quantity,
        value: holding.institution_value,
        currency_code: holding.iso_currency_code,
        cost_basis_source: holding.cost_basis,
        source: 'plaid',
        family_id: connection.family.id
      }
    end

    Holding.upsert_all(all_holdings, unique_by: :index_holdings_on_account_id_and_security_id)

    SyncPlaidInvestmentTransactionsJob.perform(item_id)
  end
end
