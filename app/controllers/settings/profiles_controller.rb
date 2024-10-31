class Settings::ProfilesController < SettingsController
  def show
    @user = Current.user
    @users = Current.family.users.order(:created_at)
  end
end
