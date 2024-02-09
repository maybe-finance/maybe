class AccountsController < ApplicationController
  before_action :authenticate_user!

  def new
    @account = Account.new(
      balance: nil,
      accountable: Accountable.from_type(params[:type])&.new
    )
  end

  def show
  end

  def create
    @account = Current.family.accounts.build(account_params)
    @account.accountable = account_params[:accountable_type].constantize.new

    if @account.save
      redirect_to accounts_path, notice: t(".success")
    else
      render "new", status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:account).permit(:name, :accountable_type, :balance, :balance_cents, :subtype)
  end

  def account_type_class
    if params[:type].present? && Account.accountable_types.include?(params[:type])
      params[:type].constantizes
    else
      Account # Default to Account if type is not provided or invalid
    end
  end
end
