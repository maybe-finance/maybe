class OtherLiabilitiesController < AccountsController
  layout :with_sidebar

  before_action :set_account, only: [ :update, :show ]

  def new
    @account = Current.family.accounts.other_liabilities.build(
      currency: Current.family.currency,
    )
  end

  def show
  end

  def create
    @account = Current.family.accounts.create_and_sync(account_params)
    redirect_to @account, notice: t(".success")
  end

  def update
    @account.update_with_sync!(account_params)
    redirect_to @account, notice: t(".success")
  end

  private
    def set_account
      @account = Current.family.accounts.other_liabilities.find_by(accountable_id: params[:id])
    end

    def account_params
      params.require(:account).permit(
        :name, :balance, :subtype, :currency, :accountable_type
      )
    end
end
