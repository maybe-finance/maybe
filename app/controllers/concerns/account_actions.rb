module AccountActions
  extend ActiveSupport::Concern

  included do
    layout :with_sidebar
    before_action :set_account, only: [ :show, :edit, :update ]
  end

  class_methods do
    def permitted_accountable_attributes(*attrs)
      @permitted_accountable_attributes = attrs if attrs.any?
      @permitted_accountable_attributes ||= [ :id ]
    end
  end

  def new
    @account = Current.family.accounts.build(
      currency: Current.family.currency,
      accountable: accountable_type.new,
    )
  end

  def show
  end

  def edit
  end

  def create
    @account = Current.family.accounts.create_and_sync(account_params)
    redirect_to @account.accountable, notice: t(".success")
  end

  def update
    @account.update_with_sync!(account_params)
    redirect_to @account.accountable, notice: t(".success")
  end

  private
    def accountable_type
      controller_name.classify.constantize
    end

    def set_account
      @account = Current.family.accounts.find_by(accountable_type: accountable_type.to_s, accountable_id: params[:id])
    end

    def account_params
      params.require(:account).permit(
        :name, :balance, :subtype, :currency, :institution_id, :accountable_type,
        accountable_attributes: self.class.permitted_accountable_attributes
      )
    end
end
