class TransactionsController < ApplicationController
  layout "with_sidebar"

  before_action :set_transaction, only: %i[ show edit update destroy ]
  before_action :set_selection

  def index
    @q = search_params
    result = Current.family.transactions.search(@q).ordered
    @pagy, @transactions = pagy(result, items: 50)

    @totals = {
      count: result.count,
      income: result.inflows.sum(&:amount_money).abs,
      expense: result.outflows.sum(&:amount_money).abs
    }
  end

  def show
  end

  def new
    @transaction = Transaction.new.tap do |txn|
      if params[:account_id]
        txn.account = Current.family.accounts.find(params[:account_id])
      end
    end
  end

  def edit
  end

  def create
    @transaction = Current.family.accounts
                     .find(params[:transaction][:account_id])
                     .transactions.build(transaction_params.merge(amount: amount))

    @transaction.save!
    @transaction.sync_account_later
    redirect_to transactions_url, notice: t(".success")
  end

  def update
    @transaction.update! transaction_params
    @transaction.sync_account_later

    redirect_to transaction_url(@transaction), notice: t(".success")
  end

  def destroy
    @transaction.destroy!
    @transaction.sync_account_later
    redirect_to transactions_url, notice: t(".success")
  end

  def toggle_selected
    if selection_params[:selected] == "1"
      session[selection_session_key] |= selection_params[:transaction_ids]
    else
      session[selection_session_key] -= selection_params[:transaction_ids]
    end

    redirect_back_or_to transactions_url
  end

  def select_all
    session[selection_session_key] = Current.family.transactions.pluck(:id)

    redirect_back_or_to transactions_url
  end

  def deselect_all
    session[selection_session_key] = []

    redirect_back_or_to transactions_url
  end

  private

    def set_selection
      @selected_transaction_ids = get_selection
    end

    def get_selection
      session[selection_session_key] ||= []
    end

    def selection_session_key
      :selected_transaction_ids
    end

    def set_transaction
      @transaction = Current.family.transactions.find(params[:id])
    end

    def amount
      if nature.income?
        transaction_params[:amount].to_d * -1
      else
        transaction_params[:amount].to_d
      end
    end

    def nature
      params[:transaction][:nature].to_s.inquiry
    end

    def selection_params
      params.require(:selection).permit(:selected, transaction_ids: [])
    end

    def search_params
      params.fetch(:q, {}).permit(:start_date, :end_date, :search, accounts: [], account_ids: [], categories: [], merchants: [])
    end

    def transaction_params
      params.require(:transaction).permit(:name, :date, :amount, :currency, :notes, :excluded, :category_id, :merchant_id, tag_ids: [], taggings_attributes: [ :id, :tag_id, :_destroy ])
    end
end
