class SyncPlaidInvestmentTransactionsJob

  def perform(item_id)
    connection = Connection.find_by(source: 'plaid', item_id: item_id)

    return if connection.nil? or connection.status == 'error' or !connection.has_investments?

    access_token = connection.access_token
    accounts = connection.accounts

    # Create a hash of account ids with matching source ids
    account_ids = accounts.map { |account| [account.source_id, account.id] }.to_h

    start_date = (connection.investments_last_synced_at || Date.today - 2.years).to_date

    request = Plaid::InvestmentsTransactionsGetRequest.new(
      {
        access_token: access_token,
        start_date: start_date,
        end_date: Date.today,
        options: {
          count: 500
        }
      }
    )

    # Rescue status code 400
    begin
      response = $plaid_api_client.investments_transactions_get(request)
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
    securities = response.securities

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

    investmentTransactions = response.investment_transactions

    # Manipulate the offset parameter to paginate transactions
    # and retrieve all available data
    while investmentTransactions.length() < response.total_investment_transactions
      request = Plaid::InvestmentsTransactionsGetRequest.new(
        {
          access_token: access_token,
          start_date: start_date,
          end_date: Date.today,
          options: {
            count: 500,
            offset: investmentTransactions.length()
          }
        }
      )
      response = $plaid_api_client.investments_transactions_get(request)
      investmentTransactions += response.investment_transactions
    end

    if investmentTransactions.any?
      investmentTransactions_hash = investmentTransactions.map do |transaction|
        security = Security.find_by(source_id: transaction.security_id)

        next if security.blank?
        {
          account_id: account_ids[transaction.account_id],
          security_id: security.id,
          date: transaction.date,
          name: transaction.name,
          amount: transaction.amount,
          quantity: transaction.quantity,
          price: transaction.price,
          fees: transaction.fees,
          currency_code: transaction.iso_currency_code,
          source_transaction_id: transaction.investment_transaction_id,
          source_type: transaction.type,
          source_subtype: transaction.subtype
        }
      end

      # Check hash for duplicate source_transaction_ids
      # If there are duplicates, remove the duplicate
      investmentTransactions_hash.compact.each_with_index do |transaction, index|
        next unless transaction[:source_transaction_id]

        if investmentTransactions_hash.count { |t| t && t[:source_transaction_id] == transaction[:source_transaction_id] } > 1
          investmentTransactions_hash.delete_at(index)
        end
      end

      investmentTransactions_hash.compact!

      InvestmentTransaction.upsert_all(investmentTransactions_hash, unique_by: :index_investment_transactions_on_source_transaction_id)

      # Update investments_last_synced_at to the current time
      connection.update(investments_last_synced_at: DateTime.now)
    end

    accounts.each do |account|
      GenerateBalanceJob.perform(account.id)
    end
  end
end
