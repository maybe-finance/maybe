class UsersController < ApplicationController
  def update
    @user = Current.user
    @user.update!(user_params)

    redirect_back_or_to settings_profile_path, notice: t(".success")
  end

  private
    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :profile_image, :onboarded,
        family_attributes: [ :name, :currency, :locale ]
      )
    end
end
