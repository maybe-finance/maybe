class Account::Transaction::RowsController < ApplicationController
  before_action :set_transaction, only: %i[ show update ]

  def show
  end

  def update
    @transaction.update! transaction_params

    redirect_to account_transaction_row_path(@transaction.account, @transaction)
  end

  private

    def transaction_params
      params.require(:transaction).permit(:category_id)
    end

    def set_transaction
      @transaction = Current.family.accounts.find(params[:account_id]).transactions.find(params[:transaction_id])
    end
end
