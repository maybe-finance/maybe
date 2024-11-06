class AccountsController < ApplicationController
  layout :with_sidebar

  before_action :set_account, only: %i[sync]

  def index
    @accounts = Current.family.accounts
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
    render layout: false
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
end
