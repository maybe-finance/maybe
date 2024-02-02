class AccountsController < ApplicationController
  before_action :authenticate_user!

  def index
    @accounts = current_family.accounts
  end

  def new
  end

  def new_bank
    @account = DepositoryAccount.new
  end

  def show
  end

  def create
    @account = account_type_class.new(account_params)
    @account.family = current_family

    if @account.save
      redirect_to accounts_path
    else
      render :new
    end
  end

  private

  def account_params
    params.require(:account).permit(:name, :balance, :type, :subtype)
  end

  def account_type_class
    if params[:type].present? && Account::VALID_ACCOUNT_TYPES.include?(params[:type])
      params[:type].constantizes
    else
      Account # Default to Account if type is not provided or invalid
    end
  end
end
