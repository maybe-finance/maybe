class TransactionsController < ApplicationController
  layout "with_sidebar"

  before_action :set_transaction, only: %i[ show edit update destroy ]

  def index
    @q = search_params
    result = Current.family.transactions.search(@q).ordered
    @pagy, @transactions = pagy(result, items: 50)

    @totals = {
      count: @transactions.count,
      income: @transactions.select { |t| t.inflow? }.sum(&:amount_money).abs,
      expense: @transactions.select { |t| t.outflow? }.sum(&:amount_money).abs
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
    if params[:transaction][:tag_id].present?
      tag = Current.family.tags.find(params[:transaction][:tag_id])
      @transaction.tags << tag unless @transaction.tags.include?(tag)
    end

    if params[:transaction][:remove_tag_id].present?
      @transaction.tags.delete(params[:transaction][:remove_tag_id])
    end

    @transaction.update! transaction_params
    @transaction.sync_account_later

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@transaction) }
      format.html { redirect_to transaction_url(@transaction), notice: t(".success") }
    end
  end

  def destroy
    @transaction.destroy!
    @transaction.sync_account_later
    redirect_to transactions_url, notice: t(".success")
  end

  private

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

    def search_params
      params.fetch(:q, {}).permit(:start_date, :end_date, :search, accounts: [], categories: [], merchants: [])
    end

    def transaction_params
      params.require(:transaction).permit(:name, :date, :amount, :currency, :notes, :excluded, :category_id, :merchant_id, :tag_id, :remove_tag_id).except(:tag_id, :remove_tag_id)
    end
end
