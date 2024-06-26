class Account::TransactionsController < ApplicationController
  layout "with_sidebar"

  before_action :set_account
  before_action :set_transaction, only: %i[ show update destroy ]

  def index
    @transactions = @account.transactions.ordered_with_entry
  end

  def show
  end

  def update
    @transaction.entry.update! transaction_entry_params
    @transaction.entry.sync_account_later

    respond_to do |format|
      format.html { redirect_back_or_to account_transaction_path(@account, @transaction), notice: t(".success") }
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@transaction) }
    end
  end

  def destroy
    @transaction.entry.destroy!
    @transaction.entry.sync_account_later
    redirect_back_or_to account_url(@transaction.entry.account), notice: t(".success")
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_transaction
      @transaction = @account.transactions.find(params[:id])
    end

    def transaction_entry_params
      params.require(:account_entry)
            .permit(:name, :date, :amount, :currency, :entryable_type, entryable_attributes: [ :notes, :excluded, :category_id, :merchant_id, tag_ids: [] ])
            # Delegated types require both of these to have values, AND they must be in this exact order (potential upstream bug)
            .with_defaults(entryable_type: "Account::Transaction", entryable_attributes: {})
    end
end
