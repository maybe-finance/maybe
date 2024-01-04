class SyncPlaidTransactionsJob
  include Sidekiq::Job

  def perform(item_id)
    connection = Connection.find_by(source: 'plaid', item_id: item_id)

    return if connection.nil?

    access_token = connection.access_token
    accounts = connection.accounts
    cursor = connection.cursor

    # Create a hash of account ids with matching source ids
    account_ids = accounts.map { |account| [account.source_id, account.id] }.to_h

    added_transactions = []
    modified_transactions = []
    removed_transactions = []
    has_more = true

    while has_more
      transactions_request = Plaid::TransactionsSyncRequest.new({
        access_token: access_token,
        cursor: cursor,
        count: 500,
        options: {
          include_personal_finance_category: true
        }
      })
      
      transactions_response = $plaid_api_client.transactions_sync(transactions_request)

      added_transactions += transactions_response.added
      modified_transactions += transactions_response.modified
      removed_transactions += transactions_response.removed

      has_more = transactions_response.has_more
      cursor = transactions_response.next_cursor
    end

    connection.update(cursor: cursor)

    if added_transactions.any?
      added_transactions_hash = added_transactions.map do |transaction|
        {
          name: transaction.name,
          amount: transaction.amount,
          is_pending: transaction.pending,
          date: transaction.date,
          account_id: account_ids[transaction.account_id],
          currency_code: transaction.iso_currency_code,
          categories: transaction.category,
          source_transaction_id: transaction.transaction_id,
          source_category_id: transaction.category_id,
          source_type: transaction.transaction_type,
          merchant_name: transaction.merchant_name,
          payment_channel: transaction.payment_channel,
          flow: transaction.amount > 0 ? 1 : 0,
          excluded: false,
          family_id: connection.family.id
        }
      end

      Transaction.upsert_all(added_transactions_hash, unique_by: %i(source_transaction_id))
    end

    if modified_transactions.any?
      modified_transactions_hash = modified_transactions.map do |transaction|
        {
          name: transaction.name,
          amount: transaction.amount,
          is_pending: transaction.pending,
          date: transaction.date,
          account_id: account_ids[transaction.account_id],
          currency_code: transaction.iso_currency_code,
          categories: transaction.category,
          source_transaction_id: transaction.transaction_id,
          source_category_id: transaction.category_id,
          source_type: transaction.transaction_type,
          merchant_name: transaction.merchant_name,
          payment_channel: transaction.payment_channel,
          flow: transaction.amount < 0 ? 1 : 0,
          excluded: false,
          family_id: connection.family.id
        }
      end

      Transaction.upsert_all(modified_transactions_hash, unique_by: %i(source_transaction_id))
    end

    if removed_transactions.any?
      Transaction.where(source_transaction_id: removed_transactions).destroy_all
    end

    EnrichTransactionsJob.perform_async

    accounts.each do |account|
      GenerateBalanceJob.perform_async(account.id)
    end
  end
end
