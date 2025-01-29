class TransactionsController < ApplicationController
  layout :with_sidebar

  before_action :restore_params_and_redirect!, only: :index, if: :should_restore_params?

  def index
    @q = search_params || {}
    @page = (params[:page] || 1).to_i
    @per_page = (params[:per_page] || 50).to_i

    store_params!(@q, @page, @per_page) if @q.present? || @page > 1 || @per_page != 50 

    search_query = Current.family.transactions.search(@q).reverse_chronological
    @pagy, @transaction_entries = pagy(search_query, limit: @per_page)

    totals_query = search_query.incomes_and_expenses
    family_currency = Current.family.currency
    count_with_transfers = search_query.count
    count_without_transfers = totals_query.count

    @totals = {
      count: ((count_with_transfers - count_without_transfers) / 2) + count_without_transfers,
      income: totals_query.income_total(family_currency).abs,
      expense: totals_query.expense_total(family_currency)
    }
  end

  def clear_filters
    Current.session.update!(prev_transaction_page_params: {})
    redirect_to transactions_path
  end

  def clear_filter_params
    params.permit(:param_key, :param_value)
  end

  def clear_filter
    updated_params = stored_params.deep_dup

    q_params = updated_params["q"] || {}

    param_key = params[:param_key]
    param_value = params[:param_value]
    
    if q_params[param_key].is_a?(Array)
      q_params[param_key].delete(param_value)
      q_params.delete(param_key) if q_params[param_key].empty?
    else
      q_params.delete(param_key)
    end

    updated_params["q"] = q_params.presence
    Current.session.update!(prev_transaction_page_params: updated_params)

    redirect_to transactions_path(updated_params)
  end

  private
    def search_params
      cleaned_params = params.fetch(:q, {})
            .permit(
              :start_date, :end_date, :search, :amount,
              :amount_operator, accounts: [], account_ids: [],
              categories: [], merchants: [], types: [], tags: []
            )
            .to_h
            .compact_blank
       
      cleaned_params.delete(:amount_operator) unless cleaned_params[:amount].present?

      cleaned_params
    end

    def store_params!(q, page, per_page)
      Current.session.update!(
        prev_transaction_page_params: {
          q: q,
          page: page,
          per_page: per_page
        }
      )
    end

    def stored_params
      Current.session.prev_transaction_page_params
    end

    def should_restore_params?
      request.query_parameters.blank? && (stored_params["q"].present? || stored_params["page"].to_i > 1 || stored_params["per_page"].to_i != 50)
    end

    def restore_params_and_redirect!
      page_value = stored_params["page"].to_i == 1 ? nil : stored_params["page"]
      per_page_value = stored_params["per_page"].to_i == 50 ? nil : stored_params["per_page"]

      redirect_to transactions_path(
        q: stored_params["q"],
        page: page_value,
        per_page: per_page_value
      )
    end
end
