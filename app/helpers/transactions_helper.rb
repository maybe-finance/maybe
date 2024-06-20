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
end
