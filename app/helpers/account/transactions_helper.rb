module Account::TransactionsHelper
  def group_transactions_by_date(transactions)
    grouped_by_date = {}

    transactions.each do |transaction|
      if transaction.transfer
        transfer_date = transaction.transfer.inflow_transaction.entry.date
        grouped_by_date[transfer_date] ||= { transactions: [], transfers: [] }
        unless grouped_by_date[transfer_date][:transfers].include?(transaction.transfer)
          grouped_by_date[transfer_date][:transfers] << transaction.transfer
        end
      else
        grouped_by_date[transaction.entry.date] ||= { transactions: [], transfers: [] }
        grouped_by_date[transaction.entry.date][:transactions] << transaction
      end
    end

    grouped_by_date
  end
end
