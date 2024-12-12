class Account::HoldingsController < ApplicationController
  layout :with_sidebar

  before_action :set_holding, only: %i[show destroy]

  def index
    @account = Current.family.accounts.find(params[:account_id])
  end

  def show
  end

  def destroy
    @holding.destroy_holding_and_entries!

    flash[:notice] = t(".success")

    respond_to do |format|
      format.html { redirect_back_or_to account_path(@holding.account) }
      format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, account_path(@holding.account)) }
    end
  end

  private
    def set_holding
      @holding = Current.family.holdings.find(params[:id])
    end
end
