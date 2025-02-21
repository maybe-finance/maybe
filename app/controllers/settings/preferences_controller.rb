class Settings::PreferencesController < ApplicationController
  layout "settings"

  def show
    @user = Current.user
  end
end
