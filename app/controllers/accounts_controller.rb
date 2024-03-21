class AccountsController < ApplicationController
  include Filterable
  before_action :authenticate_user!

  def new
    @account = Account.new(
      balance: nil,
      accountable: Accountable.from_type(params[:type])&.new
    )
  end

  def show
    @account = Current.family.accounts.find(params[:id])
    @balance_series = @account.series(period: @period)
    @valuation_series = @account.valuations.to_series
  end

  def edit
  end

  def update
    @account = Current.family.accounts.find(params[:id])

    if @account.update(account_params.except(:accountable_type))

      @account.sync_later if account_params[:is_active] == "1"

      respond_to do |format|
        format.html { redirect_to accounts_path, notice: t(".success") }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("notification-tray", partial: "shared/notification", locals: { type: "success", content: t(".success") }),
            turbo_stream.replace("account_#{@account.id}", partial: "accounts/account", locals: { account: @account })
          ]
        end
      end
    else
      render "edit", status: :unprocessable_entity
    end
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

  def sync
    @account = Current.family.accounts.find(params[:id])
    @account.sync_later

    respond_to do |format|
      format.html { redirect_to account_path(@account), notice: t(".success") }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("notification-tray", partial: "shared/notification", locals: { type: "success", content: t(".success") }),
          turbo_stream.replace("sync_message", partial: "accounts/sync_message", locals: { is_syncing: true })
        ]
      end
    end
  end

  private

  def account_params
    params.require(:account).permit(:name, :accountable_type, :balance, :currency, :subtype, :is_active)
  end
end
