class PropertiesController < ApplicationController
  before_action :set_account, only: :update

  def create
    account = Current.family.accounts.create!(account_params)
    account.sync_later
    redirect_to account, notice: t(".success")
  end

  def update
    @account.update!(account_params)
    @account.sync_later
    redirect_to @account, notice: t(".success")
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:id])
    end

    def account_params
      params.require(:account)
        .permit(
          :name, :balance, :currency, :accountable_type,
          accountable_attributes: [
            :id,
            :year_built,
            :area,
            address_attributes: [ :line1, :line2, :locality, :region, :country, :postal_code ]
          ]
        )
    end
end
