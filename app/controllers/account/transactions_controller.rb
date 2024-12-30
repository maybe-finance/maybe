class Account::TransactionsController < ApplicationController
  include EntryableResource

  permitted_entryable_attributes :id, :category_id, :merchant_id, { tag_ids: [] }

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
    selected_entries = Current.family.entries.account_transactions.where(id: bulk_update_params[:entry_ids])

    TransferMatcher.new(Current.family).match!(selected_entries)

    redirect_back_or_to transactions_url, notice: t(".success")
  end

  def unmark_transfers
    Current.family
      .entries
      .account_transactions
      .includes(:entryable)
      .where(id: bulk_update_params[:entry_ids])
      .each do |entry|
        entry.entryable.update!(category_id: nil)
      end

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
end
