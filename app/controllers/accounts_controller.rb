class AccountsController < ApplicationController
  before_action :authenticate_user!

  def new
    @account = build_account
    head :not_found unless @account
  end

  def show; end

  def create
    @account = build_and_associate_account

    render "new", status: :unprocessable_entity unless @account.save

    redirect_to accounts_path, notice: "New account created successfully"
  end

  private

  def account_params
    params.require(:account).permit(:name, :accountable_type, :balance, :subtype)
  end

  def build_account
    type = params[:type].presence
    return Account.new if type.blank? || !Account.accountable_types.include?("Account::#{type}")

    Account.new(accountable_type: "Account::#{type}")
  end

  def build_and_associate_account
    Current.family.accounts.build(account_params).tap do |account|
      account.accountable = build_accountable
    end
  end

  def build_accountable
    account_type_class(account_params[:accountable_type]).new if account_params[:accountable_type].present?
  end

  def account_type_class(type)
    return Account unless type.present? && ("#{type}").in?(Account.accountable_types)

    type.constantize
  end
end
