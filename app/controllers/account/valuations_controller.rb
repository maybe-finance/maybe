class Account::ValuationsController < ApplicationController
  layout :with_sidebar

  before_action :set_account

  def new
    @entry = @account.entries.account_valuations.new(entryable_attributes: {})
  end

  def create
    @entry = @account.entries.account_valuations.new(entry_params.merge(entryable_attributes: {}))

    if @entry.save
      @entry.sync_account_later
      redirect_back_or_to account_valuations_path(@account), notice: t(".success")
    else
      flash[:alert] = @entry.errors.full_messages.to_sentence
      redirect_to account_path(@account)
    end
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
