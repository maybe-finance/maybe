class HoldingsController < ApplicationController
  before_action :set_holding, only: %i[show destroy]

  def index
    @account = Current.family.accounts.find(params[:account_id])
  end

  def show
  end

  def destroy
    if @holding.account.plaid_account_id.present?
      flash[:alert] = "You cannot delete this holding"
    else
      @holding.destroy_holding_and_entries!
      flash[:notice] = t(".success")
    end

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
