class Settings::ProfilesController < SettingsController
  def show
  end

  def update
    user_params_with_family = user_params

    if params[:user][:delete_profile_image] == "true"
      Current.user.profile_image.purge
    end

    if Current.family && user_params_with_family[:family_attributes]
      family_attributes = user_params_with_family[:family_attributes].merge({ id: Current.family.id })
      user_params_with_family[:family_attributes] = family_attributes
    end

    if Current.user.update(user_params_with_family)
      redirect_to settings_profile_path, notice: t(".success")
    else
      redirect_to settings_profile_path, alert: Current.user.errors.full_messages.to_sentence
    end
  end

  def destroy
    if Current.user.deactivate
      logout
      redirect_to root_path, notice: t(".success")
    else
      redirect_to settings_profile_path, alert: Current.user.errors.full_messages.to_sentence
    end
  end

  private

    def user_params
      params.require(:user).permit(:first_name, :last_name, :profile_image,
                                   family_attributes: [ :name, :id ])
    end
end
