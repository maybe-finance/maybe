class CreditCardsController < ApplicationController
  before_action :set_account, only: [ :update, :show ]

  def new
    @account = Current.family.accounts.credit_cards.build(
      currency: Current.family.currency
    )
  end

  def show
  end

  def create
    account = Current.family.accounts.create_and_sync(credit_card_params)
    redirect_to account, notice: t(".success")
  end

  def update
    @account.update_with_sync!(credit_card_params)
    redirect_to @account, notice: t(".success")
  end

  private
    def set_account
      @account = Current.family.accounts.credit_cards.find_by(accountable_id: params[:id])
    end

    def credit_card_params
      params.require(:credit_card)
        .permit(
          :name, :balance, :institution_id, :currency, :accountable_type,
          accountable_attributes: [
            :id,
            :available_credit,
            :minimum_payment,
            :apr,
            :annual_fee,
            :expiration_date
          ]
        )
    end
end
