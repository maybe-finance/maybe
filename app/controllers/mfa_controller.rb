class MfaController < ApplicationController
  layout :determine_layout
  skip_authentication only: [ :verify, :verify_code ]

  def new
    Rails.logger.info "MfaController#new - User: #{Current.user.id} accessing MFA setup"
    redirect_to root_path if Current.user.otp_required?
    Current.user.setup_mfa! unless Current.user.otp_secret.present?
  end

  def create
    Rails.logger.info "MfaController#create - User: #{Current.user.id} attempting to enable MFA"
    if Current.user.verify_otp?(params[:code])
      Rails.logger.info "MfaController#create - MFA verification successful for user: #{Current.user.id}"
      Current.user.enable_mfa!
      @backup_codes = Current.user.otp_backup_codes
      Rails.logger.info "MfaController#create - Generated backup codes for user: #{Current.user.id}"
      render :backup_codes
    else
      Rails.logger.info "MfaController#create - MFA verification failed for user: #{Current.user.id}"
      Current.user.disable_mfa!
      redirect_to new_mfa_path, alert: t(".invalid_code")
    end
  end

  def verify
    Rails.logger.info "MfaController#verify - Attempting to verify MFA for user_id from session: #{session[:mfa_user_id]}"
    @user = User.find_by(id: session[:mfa_user_id])

    if @user
      Rails.logger.info "MfaController#verify - Found user: #{@user.id} for MFA verification"
    else
      Rails.logger.info "MfaController#verify - No user found for MFA verification, redirecting to login"
      redirect_to new_session_path
    end
  end

  def verify_code
    Rails.logger.info "MfaController#verify_code - Attempting to verify MFA code for user_id from session: #{session[:mfa_user_id]}"
    @user = User.find_by(id: session[:mfa_user_id])

    if @user
      Rails.logger.info "MfaController#verify_code - Found user: #{@user.id} for MFA verification"
    else
      Rails.logger.info "MfaController#verify_code - No user found for MFA verification"
    end

    if @user&.verify_otp?(params[:code])
      Rails.logger.info "MfaController#verify_code - MFA code verification successful for user: #{@user.id}"
      session.delete(:mfa_user_id)
      Rails.logger.info "MfaController#verify_code - Deleted mfa_user_id from session"

      @session = create_session_for(@user)
      Rails.logger.info "MfaController#verify_code - Created session: #{@session.id} for user: #{@user.id}"

      # Log cookie information
      Rails.logger.info "MfaController#verify_code - Cookie details:"
      Rails.logger.info "  - session_token present: #{cookies.signed[:session_token].present?}"
      Rails.logger.info "  - session_token value: #{cookies.signed[:session_token]}"
      Rails.logger.info "  - all cookies: #{cookies.to_h.keys.join(', ')}"

      # Simply redirect to root path with data-turbo="false"
      Rails.logger.info "MfaController#verify_code - Redirecting to root_path with data-turbo=false"
      redirect_to root_path, data: { turbo: false }
    else
      Rails.logger.info "MfaController#verify_code - MFA code verification failed for user: #{@user&.id}"
      flash.now[:alert] = t(".invalid_code")
      render :verify, status: :unprocessable_entity
    end
  end

  def disable
    Rails.logger.info "MfaController#disable - User: #{Current.user.id} disabling MFA"
    Current.user.disable_mfa!
    redirect_to settings_security_path, notice: t(".success")
  end

  private

    def determine_layout
      if action_name.in?(%w[verify verify_code])
        "auth"
      else
        "settings"
      end
    end
end
