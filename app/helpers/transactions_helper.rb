module TransactionsHelper
  def transaction_search_filters
    [
      { key: "account_filter", label: "Account", icon: "layers" },
      { key: "date_filter", label: "Date", icon: "calendar" },
      { key: "type_filter", label: "Type", icon: "tag" },
      { key: "amount_filter", label: "Amount", icon: "hash" },
      { key: "category_filter", label: "Category", icon: "shapes" },
      { key: "tag_filter", label: "Tag", icon: "tags" },
      { key: "merchant_filter", label: "Merchant", icon: "store" }
    ]
  end

  def get_transaction_search_filter_partial_path(filter)
    "transactions/searches/filters/#{filter[:key]}"
  end

  def get_default_transaction_search_filter
    transaction_search_filters[0]
  end
end
