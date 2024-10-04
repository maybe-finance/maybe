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
