class BalanceSheet::NetWorthSeriesBuilder
  def initialize(family)
    @family = family
  end

  def net_worth_series(period: Period.last_30_days)
    Rails.cache.fetch(cache_key(period)) do
      builder = Balance::ChartSeriesBuilder.new(
        account_ids: visible_account_ids,
        currency: family.currency,
        period: period,
        favorable_direction: "up"
      )

      builder.balance_series
    end
  end

  private
    attr_reader :family

    def visible_account_ids
      @visible_account_ids ||= family.accounts.visible.with_attached_logo.pluck(:id)
    end

    def cache_key(period)
      key = [
        "balance_sheet_net_worth_series",
        period.start_date,
        period.end_date
      ].compact.join("_")

      family.build_cache_key(
        key,
        invalidate_on_data_updates: true
      )
    end
end
