class Account::TransactionsController < ApplicationController
  include EntryableResource

  permitted_entryable_attributes :id, :category_id, :merchant_id, { tag_ids: [] }

  def new
    @entry = Current.family.entries.new(entryable: Account::Transaction.new).tap do |e|
      if params[:account_id]
        e.account = Current.family.accounts.find(params[:account_id])
        e.currency = e.account.currency
      else
        e.currency = Current.family.currency
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
    redirect_back_or_to @entry.account, notice: t(".success")
  end

  def bulk_delete
    destroyed = Current.family.entries.destroy_by(id: bulk_delete_params[:entry_ids])
    destroyed.map(&:account).uniq.each(&:sync_later)
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
    def bulk_delete_params
      params.require(:bulk_delete).permit(entry_ids: [])
    end

    def bulk_update_params
      params.require(:bulk_update).permit(:date, :notes, :category_id, :merchant_id, entry_ids: [])
    end

    def search_params
      params.fetch(:q, {})
            .permit(:start_date, :end_date, :search, :amount, :amount_operator, accounts: [], account_ids: [], categories: [], merchants: [], types: [], tags: [])
    end

    def entry_params
      base_entry_params.tap do |base_params|
        if base_params[:amount].present? && base_params[:nature].present? && base_params[:nature] == "income"
          base_params[:amount] = base_params[:amount].to_d * -1
        end

        base_params.delete(:nature)
      end
    end
end
