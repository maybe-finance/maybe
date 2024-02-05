class SettingsController < ApplicationController
  before_action :authenticate_user!

  def edit
  end

  def update
    if Current.user.update(user_params)
      redirect_to root_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation,
                                 family_attributes: [ :name, :id ])
  end
end
