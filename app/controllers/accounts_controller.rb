class AccountsController < ApplicationController
  before_action :authenticate_user!

  def new
    @account = Account.new(
      original_balance: nil,
      accountable: Accountable.from_type(params[:type])&.new
    )
  end

  def show
    # Temporary while dummy data is being used
    @account = Current.family.accounts.find(params[:id])
    @test_account = sample_account
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
    params.require(:account).permit(:name, :accountable_type, :original_balance, :original_currency, :subtype)
  end

  def sample_account
    OpenStruct.new(
      id: 1,
      name: "Sample Account",
      original_balance: BigDecimal("1115181"),
      original_currency: "USD",
      converted_balance: BigDecimal("1115181"), # Assuming conversion rate is 1 for simplicity
      converted_currency: "USD",
      dollar_change: BigDecimal("1553.43"), # Added dollar change
      percent_change: BigDecimal("0.9"), # Added percent change
      subtype: "Checking",
      accountable_type: "Depository",
      balances: sample_balances
    )
  end

  def sample_balances
    4.times.map do |i|
      OpenStruct.new(
        date: "Feb #{12 + i} 2024",
        description: "Manually entered",
        amount: BigDecimal("1000") + (i * BigDecimal("100")),
        change: i == 3 ? -50 : (i == 2 ? 0 : 100 + (i * 10)),
        percentage_change: i == 3 ? -5 : (i == 2 ? 0 : 10 + i),
        icon: i == 3 ? "arrow-down" : (i == 2 ? "minus" : (i.even? ? "arrow-down" : "arrow-up"))
      )
    end
  end
end
