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
    prev_amount = @entry.amount
    prev_date = @entry.date

    @entry.update!(entry_params.except(:origin))
    @entry.sync_account_later if prev_amount != @entry.amount || prev_date != @entry.date

    respond_to do |format|
      format.html { redirect_to account_entry_path(@account, @entry), notice: t(".success") }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          @entry,
          partial: "account/entries/entry",
          locals: entry_locals.merge(entry: @entry)
        )
      end
    end
  end

  private
    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_entry
      @entry = @account.entries.find(params[:id])
    end

    def entry_locals
      {
        selectable: entry_params[:origin].present?,
        show_balance: entry_params[:origin] == "account",
        origin: entry_params[:origin]
      }
    end

    def entry_params
      params.require(:account_entry)
            .permit(
              :name, :date, :amount, :currency, :excluded, :notes, :entryable_type, :nature, :origin,
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
