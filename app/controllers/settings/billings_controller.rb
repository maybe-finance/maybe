class Settings::BillingsController < ApplicationController
  layout "settings"

  def show
    @family = Current.family
  end
end
