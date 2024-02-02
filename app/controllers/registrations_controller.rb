class RegistrationsController < ApplicationController
  layout "auth"

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params.except(:invite_code))

    family = Family.new
    @user.family = family

    if @user.save
      login @user
      associate_invite_code_with_user if user_params[:invite_code].present?
      flash[:notice] = "You have signed up successfully."
      redirect_to root_path
    else
      flash[:alert] = "Invalid input, please try again."
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :invite_code)
  end

  def associate_invite_code_with_user
    invite_code = InviteCode.find_by(code: user_params[:invite_code])
    if invite_code && invite_code.user_id.nil?
      @user.invite_code = invite_code
      invite_code.save
    end
  end
end
