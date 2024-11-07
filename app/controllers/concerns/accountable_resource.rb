module AccountableResource
  extend ActiveSupport::Concern

  included do
    layout :with_sidebar
    before_action :set_account, only: [ :show, :edit, :update, :destroy ]
    before_action :set_link_token, only: :new, unless: -> { self_hosted? }
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
      accountable: accountable_type.new
    )
  end

  def show
  end

  def edit
  end

  def create
    @account = Current.family.accounts.create_and_sync(account_params.except(:return_to))
    redirect_to account_params[:return_to].presence || @account, notice: t(".success")
  end

  def update
    @account.update_with_sync!(account_params.except(:return_to))
    redirect_back_or_to @account, notice: t(".success")
  end

  def destroy
    @account.destroy!
    redirect_to accounts_path, notice: t(".success")
  end

  private
    def set_link_token
      @link_token = Current.family.get_link_token(
        webhooks_url: webhooks_plaid_url
      )
    end

    def accountable_type
      controller_name.classify.constantize
    end

    def set_account
      @account = Current.family.accounts.find(params[:id])
    end

    def account_params
      params.require(:account).permit(
        :name, :is_active, :balance, :subtype, :currency, :accountable_type, :return_to,
        accountable_attributes: self.class.permitted_accountable_attributes
      )
    end
end
