class TransactionsController < ApplicationController
  layout :with_sidebar

  before_action :store_params!, only: :index

  def index
    @q = search_params
    search_query = Current.family.transactions.search(@q).reverse_chronological

    if params[:focused_entry_id].present?
      @focused_entry = search_query.find_by(id: params[:focused_entry_id])
      position = search_query.pluck(:id).index(params[:focused_entry_id])

      if position.present?
        focused_page = (position / (params[:per_page] || 10).to_i) + 1
        if params[:page]&.to_i != focused_page
          return redirect_to transactions_path(page: focused_page, focused_entry_id: params[:focused_entry_id])
        else
          params.delete(:focused_entry_id)
        end
      end
    end

    @pagy, @transaction_entries = pagy(search_query, limit: params[:per_page].presence || default_params[:per_page], params: ->(params) { params.except(:focused_entry_id) })

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

    def store_params!
      if should_restore_params?
        params_to_restore = {}

        params_to_restore[:q] = stored_params["q"].presence || default_params[:q]
        params_to_restore[:page] = stored_params["page"].presence || default_params[:page]
        params_to_restore[:per_page] = stored_params["per_page"].presence || default_params[:per_page]

        redirect_to transactions_path(params_to_restore)
      else
        Current.session.update!(
          prev_transaction_page_params: {
            q: search_params,
            page: params[:page],
            per_page: params[:per_page]
          }
        )
      end
    end

    def should_restore_params?
      request.query_parameters.blank? && (stored_params["q"].present? || stored_params["page"].present? || stored_params["per_page"].present?)
    end

    def stored_params
      Current.session.prev_transaction_page_params
    end

    def default_params
      {
        q: {},
        page: 1,
        per_page: 50
      }
    end
end
