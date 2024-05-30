class TransactionsController < ApplicationController
  layout "with_sidebar"

  before_action :set_transaction, only: %i[ show edit update destroy ]

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
      params.fetch(:q, {}).permit(:start_date, :end_date, :search, accounts: [], account_ids: [], categories: [], merchants: [])
    end

    def transaction_params
      params.require(:transaction).permit(:name, :date, :amount, :currency, :notes, :excluded, :category_id, :merchant_id, tag_ids: [], taggings_attributes: [ :id, :tag_id, :_destroy ])
    end
end
