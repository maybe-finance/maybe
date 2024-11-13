class AccountsController < ApplicationController
  layout :with_sidebar

  before_action :set_account, only: %i[sync]

  def index
    @accounts = Current.family.accounts
    @plaid_items = Current.family.plaid_items
  end

  def summary
    @period = Period.from_param(params[:period])
    snapshot = Current.family.snapshot(@period)
    @net_worth_series = snapshot[:net_worth_series]
    @asset_series = snapshot[:asset_series]
    @liability_series = snapshot[:liability_series]
    @accounts = Current.family.accounts
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

    head :ok
  end

  def sync_all
    unless Current.family.syncing?
      Current.family.sync_later
    end

    head :ok
  end

  private
    def set_account
      @account = Current.family.accounts.find(params[:id])
    end
end
