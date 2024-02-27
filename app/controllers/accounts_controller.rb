class AccountsController < ApplicationController
  before_action :authenticate_user!

  def new
    @account = Account.new(
      balance: nil,
      accountable: Accountable.from_type(params[:type])&.new
    )
  end

  def show
    @account = Current.family.accounts.find(params[:id])

    @period = Period.find_by_name(params[:period])
    if @period.nil?
      start_date = params[:start_date].presence&.to_date
      end_date = params[:end_date].presence&.to_date
      if start_date.is_a?(Date) && end_date.is_a?(Date) && start_date <= end_date
        @period = Period.new(name: "custom", date_range: start_date..end_date)
      else
        params[:period] = "last_30_days"
        @period = Period.find_by_name(params[:period])
      end
    end

    @balance_series = @account.balance_series(@period)
    @valuation_series = @account.valuation_series
  end

  def create
    @account = Current.family.accounts.build(account_params.except(:accountable_type))
    @account.accountable = Accountable.from_type(account_params[:accountable_type])&.new

    if @account.save
      redirect_to accounts_path, notice: t(".success")
    else
      render "new", status: :unprocessable_entity
    end
  end

  private

  def account_params
    params.require(:account).permit(:name, :accountable_type, :balance, :currency, :subtype)
  end
end
