class EnrichTransactionsJob

  def perform
    enrichment = Faraday.new(
        url: 'https://api.ntropy.com/v2/transactions/sync',
        headers: {
          'Content-Type' => 'application/json',
          'X-API-KEY' => ENV['NTROPY_KEY']
        }
      )

    # Select transactions that have not been enriched and then batch them in groups
    Transaction.where(enriched_at: nil).group_by { |t| [t.account_id, t.date.beginning_of_month] }.each do |(account_id, date), transaction_group|
      user_id = Account.find(account_id).connection.user_id

      transactions = transaction_group.map do |transaction|
          {
            description: transaction.name,
            entry_type: transaction.amount.negative? ? 'incoming' : 'outgoing',
            amount: transaction.amount.abs.to_f,
            iso_currency_code: transaction.currency_code,
            date: transaction.date.strftime('%Y-%m-%d'),
            transaction_id: transaction.source_transaction_id,
            account_holder_id: user_id,
            account_holder_type: 'consumer'
          }
      end

      response = enrichment.post do |req|
        req.body = transactions.to_json
      end

      if response.status == 200
        JSON.parse(response.body).each do |enriched_transaction|
          transaction = Transaction.find_by(source_transaction_id: enriched_transaction['transaction_id'])
          transaction.update(
            enrichment_intermediaries: enriched_transaction['intermediaries'],
            enrichment_label_group: enriched_transaction['label_group'],
            enrichment_label: enriched_transaction['labels'].first,
            enrichment_location: enriched_transaction['location'],
            enrichment_logo: enriched_transaction['logo'],
            enrichment_mcc: enriched_transaction['mcc'],
            enrichment_merchant_name: enriched_transaction['merchant'],
            enrichment_merchant_id: enriched_transaction['merchant_id'],
            enrichment_merchant_website: enriched_transaction['website'],
            enrichment_person: enriched_transaction['person'],
            enrichment_recurrence: enriched_transaction['recurrence'],
            enrichment_recurrence_group: enriched_transaction['recurrence_group'],
            enriched_at: Time.now
          )
        end
      end
    end
  end
end
