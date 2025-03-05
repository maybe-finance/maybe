class SessionsController < ApplicationController
  before_action :set_session, only: :destroy
  skip_authentication only: %i[new create]

  layout "auth"

  def new
    Rails.logger.info "SessionsController#new - Rendering login form"
  end

  def create
    Rails.logger.info "SessionsController#create - Attempting to authenticate user with email: #{params[:email]}"

    if user = User.authenticate_by(email: params[:email], password: params[:password])
      Rails.logger.info "SessionsController#create - Authentication successful for user: #{user.id}"

      if user.otp_required?
        Rails.logger.info "SessionsController#create - MFA required for user: #{user.id}, redirecting to MFA verification"
        session[:mfa_user_id] = user.id
        redirect_to verify_mfa_path
      else
        Rails.logger.info "SessionsController#create - MFA not required for user: #{user.id}, creating session"
        @session = create_session_for(user)
        Rails.logger.info "SessionsController#create - Session created: #{@session.id}, redirecting to root_path"
        redirect_to root_path
      end
    else
      Rails.logger.info "SessionsController#create - Authentication failed for email: #{params[:email]}"
      flash.now[:alert] = t(".invalid_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    Rails.logger.info "SessionsController#destroy - Destroying session: #{@session.id} for user: #{Current.user.id}"
    @session.destroy
    redirect_to new_session_path, notice: t(".logout_successful")
  end

  private
    def set_session
      @session = Current.user.sessions.find(params[:id])
    end
end
