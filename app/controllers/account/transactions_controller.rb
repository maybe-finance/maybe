class Account::TransactionsController < ApplicationController
  layout :with_sidebar

  before_action :set_account
  before_action :set_entry, only: :update

  def index
    @pagy, @entries = pagy(
      @account.entries.account_transactions.reverse_chronological,
      limit: params[:per_page] || "10"
    )
  end

  def update
    @entry.update!(entry_params)

    respond_to do |format|
      format.html { redirect_to account_entry_path(@account, @entry), notice: t(".success") }
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@entry) }
    end
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_entry
      @entry = @account.entries.find(params[:id])
    end

    def entry_params
      params.require(:account_entry)
            .permit(
              :name, :date, :amount, :currency, :excluded, :notes, :entryable_type, :nature,
              entryable_attributes: [
                :id,
                :category_id,
                :merchant_id,
                { tag_ids: [] }
              ]
            ).tap do |permitted_params|
              nature = permitted_params.delete(:nature)

              if permitted_params[:amount]
                amount_value = permitted_params[:amount].to_d

                if nature == "income"
                  amount_value *= -1
                end

                permitted_params[:amount] = amount_value
              end
            end
    end
end
