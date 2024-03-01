class PagesController < ApplicationController
  include Filterable
  before_action :authenticate_user!

  def dashboard
    @asset_series = Current.family.asset_series(@period)
    @liability_series = Current.family.liability_series(@period)
    @net_worth_series = Current.family.net_worth_series(@period)
  end
end
