class Settings::PreferencesController < SettingsController
  def edit
  end

  def update
    preference_params_with_family = preference_params

    if Current.family && preference_params[:family_attributes]
      family_attributes = preference_params[:family_attributes].merge({ id: Current.family.id })
      preference_params_with_family[:family_attributes] = family_attributes
    end

    if Current.user.update(preference_params_with_family)
      redirect_to settings_preferences_path, notice: t(".success")
    else
      redirect_to settings_preferences_path, notice: t(".success")
      render :show, status: :unprocessable_entity
    end
  end

  private

    def preference_params
      params.require(:user).permit(family_attributes: [ :id, :currency, :locale ])
    end
end
