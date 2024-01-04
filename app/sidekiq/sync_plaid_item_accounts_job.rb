class SyncPlaidItemAccountsJob
  include Sidekiq::Job

  def perform(item_id)
    connection = Connection.find_by(source: 'plaid', item_id: item_id)

    return if connection.nil? or connection.status == 'error'

     # Rescue status code 400
    begin
      connection_accounts = $plaid_api_client.accounts_get(Plaid::AccountsGetRequest.new({ access_token: connection.access_token }))
    rescue Plaid::ApiError => e
      if e.code == 400
        # Update connection status to error and store the respoonse body in the error_message column
        connection.update(status: 'error', error: JSON.parse(e.response_body))
        return
      end
    end

    connection.update(plaid_products: connection_accounts.item.products)

    connection_accounts.accounts.each do |account|
      connection_account = Account.find_or_initialize_by(source: 'plaid', source_id: account.account_id)
      connection_account.assign_attributes(
        name: account.name,
        official_name: account.official_name,
        kind: account.type,
        subkind: account.subtype,
        available_balance: account.balances.available,
        current_balance: account.balances.current,
        current_balance_date: Date.today,
        credit_limit: account.balances.limit,
        currency_code: account.balances.iso_currency_code,
        sync_status: 'pending',
        mask: account.mask,
        connection_id: connection.id,
        family_id: connection.family_id
      )
      connection_account.save

      #GenerateBalanceJob.perform_async(connection_account.id)
    end

    connection.update(sync_status: 'idle')

    SyncPlaidTransactionsJob.perform_async(item_id)
    SyncPlaidHoldingsJob.perform_async(item_id)
  end
end
