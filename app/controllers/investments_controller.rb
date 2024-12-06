class InvestmentsController < ApplicationController
  include AccountableResource

  def create
    @account = Current.family.accounts.create_and_sync(create_params)
    redirect_to account_params[:return_to].presence || @account, notice: t("accounts.create.success", type: accountable_type.name.underscore.humanize)
  end

  private 
    def create_params
      accountable_attributes = ActionController::Parameters.new({
        cash_balance: account_params[:balance],
        holdings_balance: 0
      }).permit(:cash_balance, :holdings_balance)

      account_params.except(:return_to).merge(accountable_attributes: accountable_attributes)
    end
end
