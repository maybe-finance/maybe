class Account::TransactionsController < ApplicationController
  layout "with_sidebar"

  before_action :set_account
  before_action :set_transaction, only: %i[ show update destroy ]

  def index
    @transactions = @account.transactions.ordered
  end

  def show
  end

  def update
    @transaction.update! transaction_params
    @transaction.sync_account_later

    respond_to do |format|
      format.html { redirect_back_or_to account_transaction_path(@account, @transaction), notice: t(".success") }
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@transaction) }
    end
  end

  def destroy
    @transaction.destroy!
    @transaction.sync_account_later
    redirect_back_or_to account_url(@transaction.account), notice: t(".success")
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_transaction
      @transaction = @account.transactions.find(params[:id])
    end

    def search_params
      params.fetch(:q, {}).permit(:start_date, :end_date, :search, accounts: [], account_ids: [], categories: [], merchants: [])
    end

    def transaction_params
      params.require(:account_transaction).permit(:name, :date, :amount, :currency, :notes, :excluded, :category_id, :merchant_id, tag_ids: [])
    end
end
