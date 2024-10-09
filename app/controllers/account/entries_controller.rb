class Account::EntriesController < ApplicationController
  layout :with_sidebar

  before_action :set_account
  before_action :set_entry, only: %i[edit update show destroy]

  def edit
    render entryable_view_path(:edit)
  end

  def update
    @entry.update!(entry_params)
    @entry.sync_account_later

    respond_to do |format|
      format.html { redirect_to account_entry_path(@account, @entry), notice: t(".success") }
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@entry) }
    end
  end

  def show
    render entryable_view_path(:show)
  end

  def destroy
    @entry.destroy!
    @entry.sync_account_later
    redirect_to account_url(@entry.account), notice: t(".success")
  end

  private

    def entryable_view_path(action)
      @entry.entryable_type.underscore.pluralize + "/" + action.to_s
    end

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_entry
      @entry = @account.entries.find(params[:id])
    end

    def entry_params
      params.require(:account_entry).permit(:name, :date, :amount, :currency)
    end
end
