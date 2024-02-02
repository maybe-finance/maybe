class RegistrationsController < ApplicationController
  layout "auth"

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    family = Family.new
    @user.family = family

    if @user.save(context: :registration)
      login @user
      flash[:notice] = "You have signed up successfully."
      redirect_to root_path
    else
      flash[:alert] = "Invalid input, please try again."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :invite_code)
  end
end
