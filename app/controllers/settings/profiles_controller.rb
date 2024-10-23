class Settings::ProfilesController < SettingsController
  def show
    @user = Current.user
  end
end
