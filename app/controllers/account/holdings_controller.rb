class Account::HoldingsController < ApplicationController
  layout :with_sidebar

  before_action :set_holding, only: %i[show destroy]

  def index
    @account = Current.family.accounts.find(params[:account_id])
    @holdings = Current.family.holdings.current
    @holdings = @holdings.where(account: @account) if @account
  end

  def show
  end

  def destroy
    @holding.destroy_holding_and_entries!
    redirect_back_or_to account_holdings_path(@account)
  end

  private
    def set_holding
      @holding = Current.family.holdings.current.find(params[:id])
    end
end
