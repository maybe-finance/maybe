class Account::TransactionsController < ApplicationController
  layout :with_sidebar

  before_action :set_account
  before_action :set_entry, only: :update

  def index
    @entries = @account.entries.account_transactions.reverse_chronological
  end

  def update
    @entry.update!(entry_params.merge(amount: amount))
    @entry.sync_account_later

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
              :name, :date, :amount, :currency, :entryable_type,
              entryable_attributes: [
                :id,
                :notes,
                :excluded,
                :category_id,
                :merchant_id,
                { tag_ids: [] }
              ]
            )
    end

    def amount
      if params[:account_entry][:nature] == "income"
        entry_params[:amount].to_d * -1
      else
        entry_params[:amount].to_d
      end
    end
end
