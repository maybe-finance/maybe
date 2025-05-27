class AccountsController < ApplicationController
  before_action :set_account, only: %i[sync chart sparkline]
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
    # Pre-load the sparkline series to catch any errors before rendering
    @sparkline_series = @account.sparkline_series
    render layout: false
  rescue => e
    Rails.logger.error "Sparkline error for account #{@account.id}: #{e.message}"
    render partial: "accounts/sparkline_error", layout: false
  end

  private
    def family
      Current.family
    end

    def set_account
      @account = family.accounts.find(params[:id])
    end
end
