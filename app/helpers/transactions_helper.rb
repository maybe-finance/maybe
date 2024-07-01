module TransactionsHelper
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

  def transactions_path_without_param(param_key, param_value)
    updated_params = request.query_parameters.deep_dup

    q_params = updated_params[:q] || {}

    current_value = q_params[param_key]
    if current_value.is_a?(Array)
      q_params[param_key] = current_value - [ param_value ]
    else
      q_params.delete(param_key)
    end

    updated_params[:q] = q_params

    transactions_path(updated_params)
  end
end
