class AccountableSparklinesController < ApplicationController
  def show
    @accountable = Accountable.from_type(params[:accountable_type]&.classify)

    # Pre-load the series to catch any errors before rendering
    @series = Rails.cache.fetch(cache_key) do
      account_ids = family.accounts.active.where(accountable_type: @accountable.name).pluck(:id)

      builder = Balance::ChartSeriesBuilder.new(
        account_ids: account_ids,
        currency: family.currency,
        period: Period.last_30_days,
        favorable_direction: @accountable.favorable_direction,
        interval: "1 day"
      )

      builder.balance_series
    end

    render layout: false
  rescue => e
    Rails.logger.error "Accountable sparkline error for #{@accountable&.name}: #{e.message}"
    render partial: "accountable_sparklines/error", layout: false
  end

  private
    def family
      Current.family
    end

    def cache_key
      family.build_cache_key("#{@accountable.name}_sparkline")
    end
end
