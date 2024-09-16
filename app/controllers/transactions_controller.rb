class TransactionsController < ApplicationController
  layout :with_sidebar

  def index
    @q = search_params
    result = Current.family.entries.account_transactions.search(@q).reverse_chronological
    @pagy, @transaction_entries = pagy(result, limit: params[:per_page] || "50")

    @totals = {
      count: result.select { |t| t.currency == Current.family.currency }.count,
      income: result.income_total(Current.family.currency).abs,
      expense: result.expense_total(Current.family.currency)
    }
  end

  def new
    @entry = Current.family.entries.new(entryable: Account::Transaction.new).tap do |e|
      if params[:account_id]
        e.account = Current.family.accounts.find(params[:account_id])
      end
    end
  end

  def create
    @entry = Current.family
                    .accounts
                    .find(params[:account_entry][:account_id])
                    .entries
                    .create!(transaction_entry_params.merge(amount: amount))

    @entry.sync_account_later
    redirect_back_or_to account_path(@entry.account), notice: t(".success")
  end

  def bulk_delete
    destroyed = Current.family.entries.destroy_by(id: bulk_delete_params[:entry_ids])
    redirect_back_or_to transactions_url, notice: t(".success", count: destroyed.count)
  end

  def bulk_edit
  end

  def bulk_update
    updated = Current.family
                     .entries
                     .where(id: bulk_update_params[:entry_ids])
                     .bulk_update!(bulk_update_params)

    redirect_back_or_to transactions_url, notice: t(".success", count: updated)
  end

  def mark_transfers
    Current.family
      .entries
      .where(id: bulk_update_params[:entry_ids])
           .mark_transfers!

    redirect_back_or_to transactions_url, notice: t(".success")
  end

  def unmark_transfers
    Current.family
      .entries
      .where(id: bulk_update_params[:entry_ids])
           .update_all marked_as_transfer: false

    redirect_back_or_to transactions_url, notice: t(".success")
  end

  private

    def amount
      if nature.income?
        transaction_entry_params[:amount].to_d * -1
      else
        transaction_entry_params[:amount].to_d
      end
    end

    def nature
      params[:account_entry][:nature].to_s.inquiry
    end

    def bulk_delete_params
      params.require(:bulk_delete).permit(entry_ids: [])
    end

    def bulk_update_params
      params.require(:bulk_update).permit(:date, :notes, :category_id, :merchant_id, entry_ids: [])
    end

    def search_params
      params.fetch(:q, {}).permit(:start_date, :end_date, :search, accounts: [], account_ids: [], categories: [], merchants: [], types: [])
    end

    def transaction_entry_params
      params.require(:account_entry)
            .permit(:name, :date, :amount, :currency, :entryable_type, entryable_attributes: [ :category_id ])
            .with_defaults(entryable_type: "Account::Transaction", entryable_attributes: {})
    end
end
