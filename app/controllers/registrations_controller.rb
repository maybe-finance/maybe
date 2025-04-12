class RegistrationsController < ApplicationController
  skip_authentication

  layout "auth"

  before_action :set_user, only: :create
  before_action :set_invitation
  before_action :claim_invite_code, only: :create, if: :invite_code_required?

  def new
    @user = User.new(email: @invitation&.email)
  end

  def create
    if @invitation
      @user.family = @invitation.family
      @user.role = @invitation.role
      @user.email = @invitation.email
    else
      family = Family.new
      @user.family = family
      @user.role = :admin
    end

    if @user.save
      @invitation&.update!(accepted_at: Time.current)
      @session = create_session_for(@user)
      redirect_to root_path, notice: t(".success")
    else
      render :new, status: :unprocessable_entity, alert: t(".failure")
    end
  end

  private

    def set_invitation
      token = params[:invitation]
      token ||= params[:user][:invitation] if params[:user].present?
      @invitation = Invitation.pending.find_by(token: token)
    end

    def set_user
      @user = User.new user_params.except(:invite_code, :invitation)
    end

    def user_params(specific_param = nil)
      params = self.params.require(:user).permit(:name, :email, :password, :invite_code, :invitation)
      specific_param ? params[specific_param] : params
    end

    def claim_invite_code
      unless InviteCode.claim! params[:user][:invite_code]
        redirect_to new_registration_path, alert: t("registrations.create.invalid_invite_code")
      end
    end
end
