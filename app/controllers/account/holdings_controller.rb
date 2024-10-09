class Account::HoldingsController < ApplicationController
  layout :with_sidebar

  before_action :set_account
  before_action :set_holding, only: %i[show destroy]

  def index
    @holdings = @account.holdings.current
  end

  def show
  end

  def destroy
    @holding.destroy_holding_and_entries!
    redirect_back_or_to account_holdings_path(@account)
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_holding
      @holding = @account.holdings.current.find(params[:id])
    end
end
