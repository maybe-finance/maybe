class PagesController < ApplicationController
  include Filterable

  def dashboard
    snapshot = Current.family.snapshot(@period)
    @net_worth_series = snapshot[:net_worth_series]
    @asset_series = snapshot[:asset_series]
    @liability_series = snapshot[:liability_series]
    @account_groups = Current.family.accounts.by_group(period: @period, currency: Current.family.currency)
  end
end
