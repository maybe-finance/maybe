class VehiclesController < ApplicationController
  before_action :set_account, only: :update

  def create
    account = Current.family
                     .accounts
                     .create_with_optional_start_balance! \
                       attributes: account_params.except(:start_date, :start_balance),
                       start_date: account_params[:start_date],
                       start_balance: account_params[:start_balance]

    account.sync_later
    redirect_to account, notice: t(".success")
  end

  def update
    @account.update_with_sync!(account_params)
    redirect_to @account, notice: t(".success")
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:id])
    end

    def account_params
      params.require(:account)
        .permit(
          :name, :balance, :institution_id, :start_date, :start_balance, :currency, :accountable_type,
          accountable_attributes: [
            :id,
            :make,
            :model,
            :year,
            :mileage_value,
            :mileage_unit
          ]
        )
    end
end
