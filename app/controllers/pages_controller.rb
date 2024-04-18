class PagesController < ApplicationController
  include Filterable

  def dashboard
    snapshot = Current.family.snapshot(@period)
    @net_worth_series = snapshot[:net_worth_series]
    @asset_series = snapshot[:asset_series]
    @liability_series = snapshot[:liability_series]
    @account_groups = Current.family.accounts.by_group(period: @period, currency: Current.family.currency)

    # TODO: Placeholders for trendlines
    placeholder_series_data = 10.times.map do |i|
      { date: Date.current - i.days, value: Money.new(0) }
    end
    @income_series = TimeSeries.new(placeholder_series_data)
    @spending_series = TimeSeries.new(placeholder_series_data)
    @savings_rate_series = TimeSeries.new(10.times.map { |i| { date: Date.current - i.days, value: 0 } })
    @investing_series = TimeSeries.new(placeholder_series_data)
  end

  def changelog
  end

  def feedback
  end

  def invites
  end
end
