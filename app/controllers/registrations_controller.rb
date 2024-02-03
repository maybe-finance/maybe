class RegistrationsController < ApplicationController
  layout "auth"

  before_action :authenticate_invite_code, only: :create, if: -> { ENV["MAYBE"] }

  def new
    @user = User.new
  end

  def create
    
    @user = User.new user_params.except(:invite_code)

    family = Family.new
    @user.family = family

    if @user.save
      login @user
      consume_invite_code
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

  def authenticate_invite_code
    @invite_code = InviteCode.find_by(code: params[:user][:invite_code])
    if @invite_code.nil? || @invite_code&.expired?
      redirect_to new_registration_path, alert: "Invalid invite code"
    end
  end

  def consume_invite_code
    @invite_code.update(user: @user)
  end
end
