class AccountsController < ApplicationController
  layout "with_sidebar"

  include Filterable
  before_action :set_account, only: %i[ show update destroy sync ]

  def index
    @accounts = Current.family.accounts
  end

  def summary
    snapshot = Current.family.snapshot(@period)
    @net_worth_series = snapshot[:net_worth_series]
    @asset_series = snapshot[:asset_series]
    @liability_series = snapshot[:liability_series]
    @accounts = Current.family.accounts
    @account_groups = @accounts.by_group(period: @period, currency: Current.family.currency)
  end

  def list
  end

  def new
    @account = Account.new(
      balance: nil,
      accountable: Accountable.from_type(params[:type])&.new
    )
  end

  def show
    @balance_series = @account.series(period: @period)
    @valuation_series = @account.valuations.to_series
  end

  def edit
  end

  def update
    if @account.update(account_params.except(:accountable_type))

      @account.sync_later if @account.may_start_sync?

      respond_to do |format|
        format.html { redirect_to accounts_path, notice: t(".success") }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("notification-tray", partial: "shared/notification", locals: { type: "success", content: { body: t(".success") } }),
            turbo_stream.replace("account_#{@account.id}", partial: "accounts/account", locals: { account: @account })
          ]
        end
      end
    else
      render "show", status: :unprocessable_entity
    end
  end

  def create
    @account = Current.family.accounts.build(account_params.except(:accountable_type, :start_date))
    @account.accountable = Accountable.from_type(account_params[:accountable_type])&.new

    if @account.save
      @valuation = @account.valuations.new(date: account_params[:start_date] || Date.today, value: @account.balance, currency: @account.currency)
      @valuation.save!

      redirect_to accounts_path, notice: t(".success")
    else
      render "new", status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy!
    redirect_to accounts_path, notice: t(".success")
  end

  def sync
    if @account.may_start_sync?
      @account.sync_later
      respond_to do |format|
        format.html { redirect_to account_path(@account), notice: t(".success") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("notification-tray", partial: "shared/notification", locals: { type: "success", content: { body: t(".success") } })
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to account_path(@account), notice: t(".cannot_sync") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("notification-tray", partial: "shared/notification", locals: { type: "error", content: { body: t(".cannot_sync") } })
        end
      end
    end
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :accountable_type, :balance, :start_date, :currency, :subtype, :is_active)
    end
end
