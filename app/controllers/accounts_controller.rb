class AccountsController < ApplicationController
  layout :with_sidebar

  include Filterable
  before_action :set_account, only: %i[edit show destroy sync update]

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
    render layout: false
  end

  def new
    @account = Account.new(
      accountable: Accountable.from_type(params[:type])&.new,
      currency: Current.family.currency
    )

    @account.accountable.address = Address.new if @account.accountable.is_a?(Property)

    if params[:institution_id]
      @account.institution = Current.family.institutions.find_by(id: params[:institution_id])
    end
  end

  def show
    @series = @account.series(period: @period)
    @trend = @series.trend
  end

  def edit
    @account.accountable.build_address if @account.accountable.is_a?(Property) && @account.accountable.address.blank?
  end

  def update
    @account.update_with_sync!(account_params)
    redirect_back_or_to account_path(@account), notice: t(".success")
  end

  def create
    @account = Current.family
                      .accounts
                      .create_with_optional_start_balance! \
                        attributes: account_params.except(:start_date, :start_balance),
                        start_date: account_params[:start_date],
                        start_balance: account_params[:start_balance]
    @account.sync_later
    redirect_back_or_to account_path(@account), notice: t(".success")
  end

  def destroy
    @account.destroy!
    redirect_to accounts_path, notice: t(".success")
  end

  def sync
    unless @account.syncing?
      @account.sync_later
    end
  end

  def sync_all
    Current.family.accounts.active.sync
    redirect_back_or_to accounts_path, notice: t(".success")
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :accountable_type, :balance, :start_date, :start_balance, :currency, :subtype, :is_active, :institution_id)
    end
end
