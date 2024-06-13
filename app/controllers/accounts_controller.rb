class AccountsController < ApplicationController
  layout "with_sidebar"

  include Filterable
  before_action :set_account, only: %i[ show destroy sync update ]
  after_action :sync_account, only: :create

  def index
    @institutions = Current.family.institutions
    @accounts = Current.family.accounts.ungrouped.alphabetically
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

  def update
    @account.update! account_params.except(:accountable_type)
    redirect_back_or_to account_path(@account), notice: t(".success")
  end

  def create
    @account = Current.family
                      .accounts
                      .create_with_optional_start_balance! \
                        attributes: account_params.except(:start_date, :start_balance),
                        start_date: account_params[:start_date],
                        start_balance: account_params[:start_balance]

    redirect_to account_path(@account), notice: t(".success")
  end

  def destroy
    @account.destroy!
    redirect_to accounts_path, notice: t(".success")
  end

  def sync
    if @account.can_sync?
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
      params.require(:account).permit(:name, :accountable_type, :balance, :start_date, :start_balance, :currency, :subtype, :is_active)
    end

    def sync_account
      @account.sync_later
    end
end
