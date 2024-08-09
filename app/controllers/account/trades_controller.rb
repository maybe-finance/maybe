class Account::TradesController < ApplicationController
  layout :with_sidebar

  before_action :set_account

  def new
    @entry = @account.entries.account_trades.new(entryable_attributes: {})
  end

  def index
    @entries = @account.entries.reverse_chronological.where(entryable_type: %w[ Account::Trade Account::Transaction ])
  end

  def create
    @builder = Account::TradeBuilder.new(entry_params)

    if entry = @builder.save
      entry.sync_account_later
      redirect_to account_path(@account), notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def entry_params
      params.require(:account_entry).permit(:type, :date, :qty, :ticker, :price).merge(account: @account)
    end
end
