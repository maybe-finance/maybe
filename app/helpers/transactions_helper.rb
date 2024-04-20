module TransactionsHelper
  def transaction_filters
    [
      { name: "Account", partial: "account_filter", icon: "layers" },
      { name: "Date", partial: "date_filter", icon: "calendar" },
      { name: "Type", partial: "type_filter", icon: "shapes" },
      { name: "Amount", partial: "amount_filter", icon: "hash" },
      { name: "Category", partial: "category_filter", icon: "tag" },
      { name: "Merchant", partial: "merchant_filter", icon: "store" }
    ]
  end

  def transaction_filter_id(filter)
    "txn-#{filter[:name].downcase}-filter"
  end

  def transaction_filter_by_name(name)
    transaction_filters.find { |filter| filter[:name] == name }
  end
end
