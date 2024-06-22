class Account::TransactionsController < ApplicationController
  layout "with_sidebar"

  before_action :set_transaction, only: %i[ show update destroy ]

  def index
    @q = search_params
    result = Current.family.transactions.search(@q).ordered
    @pagy, @transactions = pagy(result, items: params[:per_page] || "10")

    @totals = {
      count: result.select { |t| t.currency == Current.family.currency }.count,
      income: result.income_total(Current.family.currency).abs,
      expense: result.expense_total(Current.family.currency)
    }
  end

  def show
  end

  def update
    @transaction.update! transaction_params
    @transaction.sync_account_later

    redirect_back_or_to account_transaction_url(@transaction.account, @transaction), notice: t(".success")
  end

  def destroy
    @transaction.destroy!
    @transaction.sync_account_later
    redirect_back_or_to account_url(@transaction.account), notice: t(".success")
  end

  private
    def set_transaction
      @transaction = Current.family.accounts.find(params[:account_id]).transactions.find(params[:id])
    end

    def search_params
      params.fetch(:q, {}).permit(:start_date, :end_date, :search, accounts: [], account_ids: [], categories: [], merchants: [])
    end

    def transaction_params
      params.require(:transaction).permit(:name, :date, :amount, :currency, :notes, :excluded, :category_id, :merchant_id, tag_ids: [])
    end
end
