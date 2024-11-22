class Account::TransactionCategoriesController < ApplicationController
  def update
    @entry = Current.family.entries.account_transactions.find(params[:transaction_id])
    @entry.update!(entry_params)

    respond_to do |format|
      format.html { redirect_back_or_to account_transaction_path(@entry) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "category_menu_account_transaction_#{@entry.account_transaction_id}",
          partial: "categories/menu",
          locals: { transaction: @entry.account_transaction }
        )
      end
    end
  end

  private
    def entry_params
      params.require(:account_entry).permit(:entryable_type, entryable_attributes: [ :id, :category_id ])
    end
end
