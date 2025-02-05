class TransactionsController < ApplicationController
  include ScrollFocusable

  layout :with_sidebar

  before_action :store_params!, only: :index

  def index
    @q = search_params
    search_query = Current.family.transactions.from_active_accounts.search(@q)

    set_focused_record(search_query, params[:focused_record_id], default_per_page: 50)

    @pagy, @transaction_entries = pagy(
      search_query.reverse_chronological.preload(
        :account,
        entryable: [
          :category, :merchant, :tags,
          :transfer_as_inflow,
          transfer_as_outflow: {
            inflow_transaction: { entry: :account },
            outflow_transaction: { entry: :account }
          }
        ]
      ),
      limit: params[:per_page].presence || default_params[:per_page],
      params: ->(params) { params.except(:focused_record_id) }
    )

    @transfers = @transaction_entries.map { |entry| entry.entryable.transfer_as_outflow }.compact
    @totals = search_query.stats(Current.family.currency)
  end

  def clear_filter
    updated_params = {
      "q" => search_params,
      "page" => params[:page],
      "per_page" => params[:per_page]
    }

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
