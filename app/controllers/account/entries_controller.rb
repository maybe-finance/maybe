class Account::EntriesController < ApplicationController
  layout :with_sidebar

  before_action :set_account
  before_action :set_entry, only: %i[edit update show destroy]

  def index
    @q = search_params
    @pagy, @entries = pagy(@account.entries.search(@q).reverse_chronological, limit: params[:per_page] || "10")
  end

  def edit
    render entryable_view_path(:edit)
  end

  def update
    prev_amount = @entry.amount
    prev_date = @entry.date

    @entry.update!(entry_params)
    @entry.sync_account_later if prev_amount != @entry.amount || prev_date != @entry.date

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
      params.require(:account_entry).permit(:name, :date, :amount, :currency, :notes)
    end

    def search_params
      params.fetch(:q, {})
            .permit(:search)
    end
end
