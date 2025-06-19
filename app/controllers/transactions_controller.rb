class TransactionsController < ApplicationController
  include ScrollFocusable, EntryableResource

  before_action :store_params!, only: :index

  def new
    super
    @income_categories = Current.family.categories.incomes.alphabetically
    @expense_categories = Current.family.categories.expenses.alphabetically
  end

  def index
    @q = search_params
    search = Transaction::Search.new(Current.family, filters: @q)
    @totals = search.totals

    per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 50

    base_scope = search.transactions_scope
                       .reverse_chronological
                       .includes(
                         { entry: :account },
                         :category, :merchant, :tags,
                         transfer_as_outflow: { inflow_transaction: { entry: :account } },
                         transfer_as_inflow: { outflow_transaction: { entry: :account } }
                       )

    @pagy, @transactions = pagy(base_scope, limit: per_page, params: ->(p) { p.except(:focused_record_id) })

    # No performance penalty by default. Only runs queries if the record is set.
    if params[:focused_record_id].present?
      set_focused_record(base_scope, params[:focused_record_id], default_per_page: per_page)
    end
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

  def create
    account = Current.family.accounts.find(params.dig(:entry, :account_id))
    @entry = account.entries.new(entry_params)

    if @entry.save
      @entry.sync_account_later
      @entry.lock_saved_attributes!
      @entry.transaction.lock_attr!(:tag_ids) if @entry.transaction.tags.any?

      flash[:notice] = "Transaction created"

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account) }
        format.turbo_stream { stream_redirect_back_or_to(account_path(@entry.account)) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @entry.update(entry_params)
      transaction = @entry.transaction

      if needs_rule_notification?(transaction)
        flash[:cta] = {
          type: "category_rule",
          category_id: transaction.category_id,
          category_name: transaction.category.name
        }
      end

      @entry.sync_account_later
      @entry.lock_saved_attributes!
      @entry.transaction.lock_attr!(:tag_ids) if @entry.transaction.tags.any?

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account), notice: "Transaction updated" }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              dom_id(@entry, :header),
              partial: "transactions/header",
              locals: { entry: @entry }
            ),
            turbo_stream.replace(@entry),
            *flash_notification_stream_items
          ]
        end
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def needs_rule_notification?(transaction)
      return false if Current.user.rule_prompts_disabled

      if Current.user.rule_prompt_dismissed_at.present?
        time_since_last_rule_prompt = Time.current - Current.user.rule_prompt_dismissed_at
        return false if time_since_last_rule_prompt < 1.day
      end

      transaction.saved_change_to_category_id? && transaction.category_id.present? &&
      transaction.eligible_for_category_rule?
    end

    def entry_params
      entry_params = params.require(:entry).permit(
        :name, :date, :amount, :currency, :excluded, :notes, :nature, :entryable_type,
        entryable_attributes: [ :id, :category_id, :merchant_id, { tag_ids: [] } ]
      )

      nature = entry_params.delete(:nature)

      if nature.present? && entry_params[:amount].present?
        signed_amount = nature == "inflow" ? -entry_params[:amount].to_d : entry_params[:amount].to_d
        entry_params = entry_params.merge(amount: signed_amount)
      end

      entry_params
    end

    def search_params
      cleaned_params = params.fetch(:q, {})
              .permit(
                :start_date, :end_date, :search, :amount,
                :amount_operator, :active_accounts_only, :excluded_transactions,
                accounts: [], account_ids: [],
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

        params_to_restore[:q] = stored_params["q"].presence || {}
        params_to_restore[:page] = stored_params["page"].presence || 1
        params_to_restore[:per_page] = stored_params["per_page"].presence || 50

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
end
