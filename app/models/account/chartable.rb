module Account::Chartable
  extend ActiveSupport::Concern

  def favorable_direction
    classification == "asset" ? "up" : "down"
  end

  def balance_series(period: Period.last_30_days, view: :balance, interval: nil)
    raise ArgumentError, "Invalid view type" unless [ :balance, :cash_balance, :holdings_balance ].include?(view.to_sym)

    @balance_series ||= {}

    memo_key = [ period.start_date, period.end_date, interval ].compact.join("_")

    builder = (@balance_series[memo_key] ||= Balance::ChartSeriesBuilder.new(
      account_ids: [ id ],
      currency: self.currency,
      period: period,
      favorable_direction: favorable_direction,
      interval: interval
    ))

    builder.send("#{view}_series")
  end

  def sparkline_series
    cache_key = family.build_cache_key("#{id}_sparkline")

    Rails.cache.fetch(cache_key) do
      balance_series
    end
  end
end
