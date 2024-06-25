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

    redirect_back_or_to account_transaction_url(@transaction.account, @transaction), notice: t(".success")
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
      @entry = @transaction.entry
    end

    def search_params
      params.fetch(:q, {}).permit(:start_date, :end_date, :search, accounts: [], account_ids: [], categories: [], merchants: [])
    end

    def entry_params
      params.require(:account_entry).permit(:name, :date, :amount, :currency, entryable_attributes: [ :notes, :excluded, :category_id, :merchant_id, tag_ids: [] ])
    end
end
