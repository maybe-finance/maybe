class AccountsController < ApplicationController
  before_action :set_account, only: %i[sync]

  def index
    @manual_accounts = Current.family.accounts.manual.alphabetically
    @plaid_items = Current.family.plaid_items.ordered

    render layout: "settings"
  end

  def summary
    @period = Period.from_param(params[:period])
    snapshot = Current.family.snapshot(@period)
    @net_worth_series = snapshot[:net_worth_series]
    @asset_series = snapshot[:asset_series]
    @liability_series = snapshot[:liability_series]
    @accounts = Current.family.accounts.active
    @account_groups = @accounts.by_group(period: @period, currency: Current.family.currency)
  end

  def list
    @period = Period.from_param(params[:period])
    render layout: false
  end

  def sync
    unless @account.syncing?
      @account.sync_later
    end

    redirect_to account_path(@account)
  end

  def chart
    @account = Current.family.accounts.find(params[:id])
    render layout: "application"
  end

  def sparkline
    @account = Current.family.accounts.find(params[:id])
    render layout: false
  end

  def sync_all
    unless Current.family.syncing?
      Current.family.sync_later
    end

    redirect_to accounts_path
  end

  private
    def set_account
      @account = Current.family.accounts.find(params[:id])
    end
end
