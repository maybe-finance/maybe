class Transaction::RowsController < ApplicationController
  before_action :set_transaction, only: %i[ show update ]

  def show
  end

  def update
    @transaction.update! transaction_params

    redirect_to transaction_row_path(@transaction)
  end

  private

    def transaction_params
      params.require(:transaction).permit(:category_id)
    end

    def set_transaction
      @transaction = Current.family.transactions.find(params[:id])
    end
end
