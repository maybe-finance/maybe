module TransactionsHelper
  def transaction_search_filters
    [
      { key: "account_filter", icon: "layers" },
      { key: "date_filter", icon: "calendar" },
      { key: "type_filter", icon: "tag" },
      { key: "amount_filter", icon: "hash" },
      { key: "category_filter", icon: "shapes" },
      { key: "tag_filter", icon: "tags" },
      { key: "merchant_filter", icon: "store" }
    ]
  end

  def get_transaction_search_filter_partial_path(filter)
    "transactions/searches/filters/#{filter[:key]}"
  end

  def get_default_transaction_search_filter
    transaction_search_filters[0]
  end
end
