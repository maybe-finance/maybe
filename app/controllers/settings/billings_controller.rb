class Settings::BillingsController < SettingsController
  def show
    @user = Current.user
  end
end
