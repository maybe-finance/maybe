class Account::TransactionsController < ApplicationController
  include EntryableResource

  permitted_entryable_attributes :id, :category_id, :merchant_id, { tag_ids: [] }

  def update
    if @entry.update(update_entry_params)
      @entry.sync_account_later

      transaction = @entry.account_transaction

      if needs_rule_notification?(transaction)
        flash[:cta] = {
          type: "category_rule",
          category_id: transaction.category_id,
          category_name: transaction.category.name
        }
      end

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account), notice: t("account.entries.update.success") }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "header_account_entry_#{@entry.id}",
              partial: "account/transactions/header",
              locals: { entry: @entry }
            ),
            turbo_stream.replace("account_entry_#{@entry.id}", partial: "account/entries/entry", locals: { entry: @entry }),
            *flash_notification_stream_items
          ]
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
    def needs_rule_notification?(transaction)
      return false if Current.user.rule_prompts_disabled

      if Current.user.rule_prompt_dismissed_at.present?
        time_since_last_rule_prompt = Time.current - Current.user.rule_prompt_dismissed_at
        return false if time_since_last_rule_prompt < 1.day
      end

      transaction.saved_change_to_category_id? &&
      transaction.eligible_for_category_rule?
    end

    def bulk_delete_params
      params.require(:bulk_delete).permit(entry_ids: [])
    end

    def bulk_update_params
      params.require(:bulk_update).permit(:date, :notes, :category_id, :merchant_id, entry_ids: [], tag_ids: [])
    end

    def search_params
      params.fetch(:q, {})
            .permit(:start_date, :end_date, :search, :amount, :amount_operator, accounts: [], account_ids: [], categories: [], merchants: [], types: [], tags: [])
    end
end
