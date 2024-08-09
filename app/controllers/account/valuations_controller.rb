class Account::ValuationsController < ApplicationController
  layout :with_sidebar

  before_action :set_account

  def new
    @entry = @account.entries.account_valuations.new
  end

  def create
    entry = @account.entries.account_valuations.create!(entry_params.merge(entryable_attributes: {}))
    entry.sync_account_later
    redirect_to account_valuations_path(@account), notice: t(".success")
  end

  def index
    @entries = @account.entries.account_valuations.reverse_chronological
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def entry_params
      params.require(:account_entry).permit(:name, :date, :amount, :currency)
    end
end
