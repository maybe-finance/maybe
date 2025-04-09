class Account::TransactionsController < ApplicationController
  include EntryableResource

  permitted_entryable_attributes :id, :category_id, :merchant_id, { tag_ids: [] }

  def update
    if @entry.update(update_entry_params)
      @entry.sync_account_later

      if @entry.account_transaction.saved_change_to_category_id? && @entry.account_transaction.eligible_for_category_rule?
        flash[:cta] = {
          message: "Updated to #{@entry.account_transaction.category.name}",
          description: "You can create a rule to automatically categorize transactions like this one",
          accept_label: "Create rule",
          accept_href: new_rule_path(resource_type: "transaction"),
          accept_turbo_frame: "modal",
          decline_label: "Dismiss"
        }
      else
        flash[:notice] = "Transaction updated"
      end

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account), notice: t("account.entries.update.success") }
        format.turbo_stream do
          items = [
            turbo_stream.replace(
              "header_account_entry_#{@entry.id}",
              partial: "account/transactions/header",
              locals: { entry: @entry }
            ),
            turbo_stream.replace("account_entry_#{@entry.id}", partial: "account/entries/entry", locals: { entry: @entry })
          ]

          if flash[:cta].present?
            items << turbo_stream.replace("cta", partial: "shared/notifications/cta", locals: { cta: flash[:cta] })
          end

          render turbo_stream: items
        end
      end
    else
      render :show, status: :unprocessable_entity
    end
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
