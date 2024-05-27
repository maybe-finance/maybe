module TransactionsHelper
  def full_width_transaction_row?(route)
    route != "/"
  end
end
