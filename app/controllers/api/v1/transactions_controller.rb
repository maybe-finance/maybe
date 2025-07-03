# frozen_string_literal: true

class Api::V1::TransactionsController < Api::V1::BaseController
  include Pagy::Backend

  # Ensure proper scope authorization for read vs write access
  before_action :ensure_read_scope, only: [ :index, :show ]
  before_action :ensure_write_scope, only: [ :create, :update, :destroy ]
  before_action :set_transaction, only: [ :show, :update, :destroy ]

  def index
    family = current_resource_owner.family
    transactions_query = family.transactions.visible

    # Apply filters
    transactions_query = apply_filters(transactions_query)

    # Apply search
    transactions_query = apply_search(transactions_query) if params[:search].present?

    # Include necessary associations for efficient queries
    transactions_query = transactions_query.includes(
      { entry: :account },
      :category, :merchant, :tags,
      transfer_as_outflow: { inflow_transaction: { entry: :account } },
      transfer_as_inflow: { outflow_transaction: { entry: :account } }
    ).reverse_chronological

    # Handle pagination with Pagy
    @pagy, @transactions = pagy(
      transactions_query,
      page: safe_page_param,
      limit: safe_per_page_param
    )

    # Make per_page available to the template
    @per_page = safe_per_page_param

    # Rails will automatically use app/views/api/v1/transactions/index.json.jbuilder
    render :index

  rescue => e
    Rails.logger.error "TransactionsController#index error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def show
    # Rails will automatically use app/views/api/v1/transactions/show.json.jbuilder
    render :show

  rescue => e
    Rails.logger.error "TransactionsController#show error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def create
    family = current_resource_owner.family

    # Validate account_id is present
    unless transaction_params[:account_id].present?
      render json: {
        error: "validation_failed",
        message: "Account ID is required",
        errors: [ "Account ID is required" ]
      }, status: :unprocessable_entity
      return
    end

    account = family.accounts.find(transaction_params[:account_id])
    @entry = account.entries.new(entry_params_for_create)

    if @entry.save
      @entry.sync_account_later
      @entry.lock_saved_attributes!
      @entry.transaction.lock_attr!(:tag_ids) if @entry.transaction.tags.any?

      @transaction = @entry.transaction
      render :show, status: :created
    else
      render json: {
        error: "validation_failed",
        message: "Transaction could not be created",
        errors: @entry.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue => e
    Rails.logger.error "TransactionsController#create error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
end

  def update
    if @entry.update(entry_params_for_update)
      @entry.sync_account_later
      @entry.lock_saved_attributes!
      @entry.transaction.lock_attr!(:tag_ids) if @entry.transaction.tags.any?

      @transaction = @entry.transaction
      render :show
    else
      render json: {
        error: "validation_failed",
        message: "Transaction could not be updated",
        errors: @entry.errors.full_messages
      }, status: :unprocessable_entity
    end

  rescue => e
    Rails.logger.error "TransactionsController#update error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  def destroy
    @entry.destroy!
    @entry.sync_account_later

    render json: {
      message: "Transaction deleted successfully"
    }, status: :ok

  rescue => e
    Rails.logger.error "TransactionsController#destroy error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "internal_server_error",
      message: "Error: #{e.message}"
    }, status: :internal_server_error
  end

  private

    def set_transaction
      family = current_resource_owner.family
      @transaction = family.transactions.find(params[:id])
      @entry = @transaction.entry
    rescue ActiveRecord::RecordNotFound
      render json: {
        error: "not_found",
        message: "Transaction not found"
      }, status: :not_found
    end

    def ensure_read_scope
      authorize_scope!(:read)
    end

    def ensure_write_scope
      authorize_scope!(:write)
    end

    def apply_filters(query)
      # Account filtering
      if params[:account_id].present?
        query = query.joins(:entry).where(entries: { account_id: params[:account_id] })
      end

      if params[:account_ids].present?
        account_ids = Array(params[:account_ids])
        query = query.joins(:entry).where(entries: { account_id: account_ids })
      end

      # Category filtering
      if params[:category_id].present?
        query = query.where(category_id: params[:category_id])
      end

      if params[:category_ids].present?
        category_ids = Array(params[:category_ids])
        query = query.where(category_id: category_ids)
      end

      # Merchant filtering
      if params[:merchant_id].present?
        query = query.where(merchant_id: params[:merchant_id])
      end

      if params[:merchant_ids].present?
        merchant_ids = Array(params[:merchant_ids])
        query = query.where(merchant_id: merchant_ids)
      end

      # Date range filtering
      if params[:start_date].present?
        query = query.joins(:entry).where("entries.date >= ?", Date.parse(params[:start_date]))
      end

      if params[:end_date].present?
        query = query.joins(:entry).where("entries.date <= ?", Date.parse(params[:end_date]))
      end

      # Amount filtering
      if params[:min_amount].present?
        min_amount = params[:min_amount].to_f
        query = query.joins(:entry).where("entries.amount >= ?", min_amount)
      end

      if params[:max_amount].present?
        max_amount = params[:max_amount].to_f
        query = query.joins(:entry).where("entries.amount <= ?", max_amount)
      end

      # Tag filtering
      if params[:tag_ids].present?
        tag_ids = Array(params[:tag_ids])
        query = query.joins(:tags).where(tags: { id: tag_ids })
      end

      # Transaction type filtering (income/expense)
      if params[:type].present?
        case params[:type].downcase
        when "income"
          query = query.joins(:entry).where("entries.amount < 0")
        when "expense"
          query = query.joins(:entry).where("entries.amount > 0")
        end
      end

      query
    end

    def apply_search(query)
      search_term = "%#{params[:search]}%"

      query.joins(:entry)
           .left_joins(:merchant)
           .where(
             "entries.name ILIKE ? OR entries.notes ILIKE ? OR merchants.name ILIKE ?",
             search_term, search_term, search_term
           )
end

    def transaction_params
      params.require(:transaction).permit(
        :account_id, :date, :amount, :name, :description, :notes, :currency,
        :category_id, :merchant_id, :nature, tag_ids: []
      )
    end

    def entry_params_for_create
      entry_params = {
        name: transaction_params[:name] || transaction_params[:description],
        date: transaction_params[:date],
        amount: calculate_signed_amount,
        currency: transaction_params[:currency] || current_resource_owner.family.currency,
        notes: transaction_params[:notes],
        entryable_type: "Transaction",
        entryable_attributes: {
          category_id: transaction_params[:category_id],
          merchant_id: transaction_params[:merchant_id],
          tag_ids: transaction_params[:tag_ids] || []
        }
      }

      entry_params.compact
    end

    def entry_params_for_update
      entry_params = {
        name: transaction_params[:name] || transaction_params[:description],
        date: transaction_params[:date],
        notes: transaction_params[:notes],
        entryable_attributes: {
          id: @entry.entryable_id,
          category_id: transaction_params[:category_id],
          merchant_id: transaction_params[:merchant_id],
          tag_ids: transaction_params[:tag_ids]
        }.compact_blank
      }

      # Only update amount if provided
      if transaction_params[:amount].present?
        entry_params[:amount] = calculate_signed_amount
      end

      entry_params.compact
    end

    def calculate_signed_amount
      amount = transaction_params[:amount].to_f
      nature = transaction_params[:nature]

      case nature&.downcase
      when "income", "inflow"
        -amount.abs  # Income is negative
      when "expense", "outflow"
        amount.abs   # Expense is positive
      else
        amount       # Use as provided
      end
    end

    def safe_page_param
      page = params[:page].to_i
      page > 0 ? page : 1
    end

    def safe_per_page_param
      per_page = params[:per_page].to_i
      case per_page
      when 1..100
        per_page
      else
        25  # Default
      end
    end
end
