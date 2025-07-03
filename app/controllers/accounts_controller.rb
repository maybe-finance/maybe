class AccountsController < ApplicationController
  before_action :set_account, only: %i[sync chart sparkline toggle_active]
  include Periodable

  def index
    @manual_accounts = family.accounts.manual.alphabetically
    @plaid_items = family.plaid_items.ordered

    render layout: "settings"
  end

  def sync
    unless @account.syncing?
      @account.sync_later
    end

    redirect_to account_path(@account)
  end

  def chart
    @chart_view = params[:chart_view] || "balance"
    render layout: "application"
  end

  def sparkline
    etag_key = @account.family.build_cache_key("#{@account.id}_sparkline", invalidate_on_data_updates: true)

    # Short-circuit with 304 Not Modified when the client already has the latest version.
    # We defer the expensive series computation until we know the content is stale.
    if stale?(etag: etag_key, last_modified: @account.family.latest_sync_completed_at)
      @sparkline_series = @account.sparkline_series
      render layout: false
    end
  end

  def toggle_active
    if @account.active?
      @account.disable!
    elsif @account.disabled?
      @account.enable!
    end
    redirect_to accounts_path
  end

  private
    def family
      Current.family
    end

    def set_account
      @account = family.accounts.find(params[:id])
    end
end
