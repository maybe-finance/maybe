class Account::HoldingsController < ApplicationController
  layout "with_sidebar"

  before_action :set_account

  def index
    @holdings = @account.holdings.current
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end
end
