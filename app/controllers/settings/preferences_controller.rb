class Settings::PreferencesController < ApplicationController
  def show
    @user = Current.user
  end
end
