class AccountableSparklinesController < ApplicationController
  def show
    @accountable = Accountable.from_type(params[:accountable_type]&.classify)

    @series = Rails.cache.fetch(cache_key) do
      family.accounts.active
              .where(accountable_type: @accountable.name)
              .balance_series(
                currency: family.currency,
                timezone: family.timezone,
                favorable_direction: @accountable.favorable_direction
              )
    end

    render layout: false
  end

  private
    def family
      Current.family
    end

    def cache_key
      family.build_cache_key("#{@accountable.name}_sparkline")
    end
end
