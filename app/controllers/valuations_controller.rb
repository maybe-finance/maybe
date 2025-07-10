class ValuationsController < ApplicationController
  include EntryableResource, StreamExtensions

  def create
    account = Current.family.accounts.find(params.dig(:entry, :account_id))

    if entry_params[:date].to_date == Date.current
      account.update_current_balance!(balance: entry_params[:amount].to_d)
    else
      account.reconcile_balance!(
        balance: entry_params[:amount].to_d,
        date: entry_params[:date].to_date
      )
    end

    account.sync_later

    respond_to do |format|
      format.html { redirect_back_or_to account_path(account), notice: "Account value updated" }
      format.turbo_stream { stream_redirect_back_or_to(account_path(account), notice: "Account value updated") }
    end
  end

  def update
    # ActiveRecord::Base.transaction do
    @entry.account.reconcile_balance!(
      balance: entry_params[:amount].to_d,
      date: entry_params[:date].to_date
    )

    if entry_params[:notes].present?
      @entry.update!(notes: entry_params[:notes])
    end

    @entry.account.sync_later

    @entry.reload

    respond_to do |format|
      format.html { redirect_back_or_to account_path(@entry.account), notice: "Account value updated" }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@entry, :header),
            partial: "valuations/header",
            locals: { entry: @entry }
          ),
          turbo_stream.replace(@entry)
        ]
      end
    end
  end

  private
    def entry_params
      params.require(:entry).permit(:date, :amount, :notes)
    end
end
