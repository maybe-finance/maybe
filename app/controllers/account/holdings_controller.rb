class Account::HoldingsController < ApplicationController
  layout :with_sidebar

  before_action :set_account
  before_action :set_holding, only: :show

  def index
    @holdings = @account.holdings.current
  end

  def show
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_holding
      @holding = @account.holdings.current.find(params[:id])
    end
end
