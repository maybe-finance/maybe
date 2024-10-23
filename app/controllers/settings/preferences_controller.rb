class Settings::PreferencesController < SettingsController
  def show
    @user = Current.user
  end
end
