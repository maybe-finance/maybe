class BalanceSheet::NetWorthSeries
  def initialize(family)
    @family = family
  end

  def net_worth_series(period: Period.last_30_days)
    Rails.cache.fetch(cache_key(period)) do
      builder = Balance::ChartSeriesBuilder.new(
        account_ids: active_account_ids,
        currency: family.currency,
        period: period,
        favorable_direction: "up"
      )

      builder.balance_series
    end
  end

  private
    attr_reader :family

    def active_account_ids
      @active_account_ids ||= family.accounts.active.with_attached_logo.pluck(:id)
    end

    def cache_key(period)
      [
        "balance_sheet_net_worth_series",
        family.id,
        period.start_date,
        period.end_date,
        family.latest_sync_completed_at # If account sync completes, need a refresh
      ].join("_")
    end
end
