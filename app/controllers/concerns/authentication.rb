module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_request_details
    before_action :authenticate_user!
    before_action :set_sentry_user
  end

  class_methods do
    def skip_authentication(**options)
      skip_before_action :authenticate_user!, **options
      skip_before_action :set_sentry_user, **options
    end
  end

  private
    def authenticate_user!
      Rails.logger.info "Authentication#authenticate_user! - Checking for session cookie"

      if session_record = find_session_by_cookie
        Rails.logger.info "Authentication#authenticate_user! - Found valid session: #{session_record.id} for user: #{session_record.user_id}"
        Current.session = session_record
      else
        Rails.logger.info "Authentication#authenticate_user! - No valid session found"

        if self_hosted_first_login?
          Rails.logger.info "Authentication#authenticate_user! - Self-hosted first login detected, redirecting to registration"
          redirect_to new_registration_url
        else
          Rails.logger.info "Authentication#authenticate_user! - Redirecting to login page"
          redirect_to new_session_url
        end
      end
    end

    def find_session_by_cookie
      cookie_value = cookies.signed[:session_token]
      Rails.logger.info "Authentication#find_session_by_cookie - Looking for session with cookie value: #{cookie_value.present? ? 'present' : 'missing'}"

      if cookie_value.present?
        session = Session.find_by(id: cookie_value)
        Rails.logger.info "Authentication#find_session_by_cookie - Session found: #{session.present? ? 'yes' : 'no'}"

        if session.present?
          Rails.logger.info "Authentication#find_session_by_cookie - Session belongs to user: #{session.user_id}"
        end

        session
      else
        Rails.logger.info "Authentication#find_session_by_cookie - No session cookie found"
        nil
      end
    end

    def create_session_for(user)
      Rails.logger.info "Authentication#create_session_for - Creating session for user: #{user.id}"
      session = user.sessions.create!
      Rails.logger.info "Authentication#create_session_for - Session created with ID: #{session.id}"

      Rails.logger.info "Authentication#create_session_for - Setting session cookie"
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }

      Rails.logger.info "Authentication#create_session_for - Cookie set, verifying..."
      cookie_value = cookies.signed[:session_token]
      Rails.logger.info "Authentication#create_session_for - Cookie verification: #{cookie_value == session.id ? 'successful' : 'failed'}"

      session
    end

    def self_hosted_first_login?
      Rails.application.config.app_mode.self_hosted? && User.count.zero?
    end

    def set_request_details
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
    end

    def set_sentry_user
      return unless defined?(Sentry) && ENV["SENTRY_DSN"].present?

      if Current.user
        Sentry.set_user(
          id: Current.user.id,
          email: Current.user.email,
          username: Current.user.display_name,
          ip_address: Current.ip_address
        )
      end
    end
end
