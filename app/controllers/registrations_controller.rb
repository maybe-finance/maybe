class RegistrationsController < ApplicationController
  skip_authentication

  layout "auth"

  before_action :set_user, only: :create
  before_action :claim_invite_code, only: :create, if: :invite_code_required?

  def new
    @user = User.new
  end

  def create
    family = Family.new
    @user.family = family

    if @user.save
      Transaction::Category.create_default_categories(@user.family)
      login @user
      flash[:notice] = t(".success")
      redirect_to root_path
    else
      flash[:alert] = t(".failure")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.new user_params.except(:invite_code)
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :invite_code)
  end

  def claim_invite_code
    unless InviteCode.claim! params[:user][:invite_code]
      redirect_to new_registration_path, alert: t("registrations.create.invalid_invite_code")
    end
  end
end
