class AccountsController < ApplicationController
  before_action :authenticate_user!

  def new
    if params[:type].blank? || Account.accountable_types.include?("Account::#{params[:type]}")
      @account = if params[:type].blank?
        Account.new
      else
        Account.new(accountable_type: "Account::#{params[:type]}")
      end
    else
      head :not_found
    end
  end

  def show
  end

  def create
    @account = current_family.accounts.build(account_params)
    @account.accountable = account_params[:accountable_type].constantize.new

    if @account.save
      redirect_to accounts_path, notice: "New account created successfully"
    else
      render "new", status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:account).permit(:name, :accountable_type, :balance, :subtype)
  end

  def account_type_class
    if params[:type].present? && Account.accountable_types.include?(params[:type])
      params[:type].constantizes
    else
      Account # Default to Account if type is not provided or invalid
    end
  end
end
