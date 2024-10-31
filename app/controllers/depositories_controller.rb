class DepositoriesController < AccountsController
  before_action :set_account, only: [ :update ]

  def new
    @account = Current.family.accounts.depositories.build(
      currency: Current.family.currency,
    )
  end

  def create
    @account = Current.family.accounts.create!(
      depository_params.merge(accountable: Depository.new)
    )
    redirect_to @account, notice: t(".success")
  end

  def update
    @account.update_with_sync!(depository_params)
    redirect_to @account, notice: t(".success")
  end

  private
    def set_account
      @account = Current.family.accounts.depositories.find_by(accountable_id: params[:id])
    end

    def depository_params
      params.require(:depository).permit(
        :name, :balance, :subtype, :currency
      )
    end
end
