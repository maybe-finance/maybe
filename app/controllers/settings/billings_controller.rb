class Settings::BillingsController < ApplicationController
  layout "settings"

  def show
    @user = Current.user
  end
end
