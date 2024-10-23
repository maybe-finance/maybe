class UsersController < ApplicationController
  def update
    @user = Current.user

    @user.update!(user_params)
    @user.profile_image.purge if should_purge_profile_image?

    redirect_back_or_to settings_profile_path, notice: t(".success")
  end

  private
    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :profile_image, :onboarded,
        family_attributes: [ :name, :currency, :locale, :id ]
      )
    end

    def should_purge_profile_image?
      params[:user][:delete_profile_image] == "1" &&
        params[:user][:profile_image].blank?
    end
end
