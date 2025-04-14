class TransactionCategoriesController < ApplicationController
  def update
    @entry = Current.family.entries.transactions.find(params[:transaction_id])
    @entry.update!(entry_params)

    respond_to do |format|
      format.html { redirect_back_or_to transaction_path(@entry) }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "category_menu_transaction_#{@entry.transaction_id}",
          partial: "categories/menu",
          locals: { transaction: @entry.transaction }
        )
      end
    end
  end

  private
    def entry_params
      params.require(:entry).permit(:entryable_type, entryable_attributes: [ :id, :category_id ])
    end
end
