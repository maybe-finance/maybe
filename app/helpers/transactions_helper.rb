module TransactionsHelper
  def transactions_group(date, transactions, transaction_partial_path = "transactions/transaction")
    header_left = content_tag :span do
      "#{date.strftime('%b %d, %Y')} · #{transactions.size}".html_safe
    end

    header_right = content_tag :span do
      format_money(-transactions.sum(&:amount_money))
    end

    header = header_left.concat(header_right)

    content = render partial: transaction_partial_path, collection: transactions

    render partial: "shared/list_group", locals: {
      header: header,
      content: content
    }
  end

  def unconfirmed_transfer?(transaction)
    transaction.marked_as_transfer && transaction.transfer.nil?
  end

  def group_transactions_by_date(transactions)
    grouped_by_date = {}

    transactions.each do |transaction|
      if transaction.transfer
        transfer_date = transaction.transfer.inflow_transaction.date
        grouped_by_date[transfer_date] ||= { transactions: [], transfers: [] }
        unless grouped_by_date[transfer_date][:transfers].include?(transaction.transfer)
          grouped_by_date[transfer_date][:transfers] << transaction.transfer
        end
      else
        grouped_by_date[transaction.date] ||= { transactions: [], transfers: [] }
        grouped_by_date[transaction.date][:transactions] << transaction
      end
    end

    grouped_by_date
  end
end
