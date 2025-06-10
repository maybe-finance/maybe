class BalanceSheet
  include Monetizable

  monetize :net_worth

  attr_reader :family

  def initialize(family)
    @family = family
  end

  def assets
    @assets ||= ClassificationGroup.new(
      classification: "asset",
      currency: family.currency,
      accounts: account_totals.asset_accounts
    )
  end

  def liabilities
    @liabilities ||= ClassificationGroup.new(
      classification: "liability",
      currency: family.currency,
      accounts: account_totals.liability_accounts
    )
  end

  def classification_groups
    [ assets, liabilities ]
  end

  def account_groups
    [ assets.account_groups, liabilities.account_groups ].flatten
  end

  def net_worth
    assets.total - liabilities.total
  end

  def net_worth_series(period: Period.last_30_days)
    memo_key = [ period.start_date, period.end_date ].compact.join("_")

    @net_worth_series ||= {}

    account_ids = active_accounts.pluck(:id)

    builder = (@net_worth_series[memo_key] ||= Balance::ChartSeriesBuilder.new(
      account_ids: account_ids,
      currency: currency,
      period: period,
      favorable_direction: "up"
    ))

    builder.balance_series
  end

  def currency
    family.currency
  end

  def syncing?
    sync_status_monitor.syncing?
  end

  private
    def sync_status_monitor
      @sync_status_monitor ||= BalanceSheet::SyncStatusMonitor.new(family)
    end

    def account_totals
      @account_totals ||= BalanceSheet::AccountTotals.new(family, sync_status_monitor: sync_status_monitor)
    end

    def active_accounts
      family.accounts.active.with_attached_logo
    end
end
