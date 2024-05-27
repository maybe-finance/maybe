module Transactions::SearchesHelper
  def transaction_search_filters
    [
      { key: "account_filter", name: "Account", icon: "layers" },
      { key: "date_filter", name: "Date", icon: "calendar" },
      { key: "type_filter", name: "Type", icon: "shapes" },
      { key: "amount_filter", name: "Amount", icon: "hash" },
      { key: "category_filter", name: "Category", icon: "tag" },
      { key: "merchant_filter", name: "Merchant", icon: "store" }
    ]
  end

  def get_transaction_search_filter_partial_path(filter)
    "transactions/searches/filters/#{filter[:key]}"
  end

  def get_default_transaction_search_filter
    transaction_search_filters[0]
  end
end
