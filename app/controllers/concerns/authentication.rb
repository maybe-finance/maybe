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
      if session_record = find_session_by_cookie
        Current.session = session_record
      elsif session_record = create_session_by_remote_header
        Current.session = session_record
      else
        if self_hosted_first_login?
          redirect_to new_registration_url
        else
          redirect_to new_session_url
        end
      end
    end

    def create_session_by_remote_header
      if user_email = request.headers[Rails.application.config.remote_login_email_header_name]
        unless user = User.find_by(email: user_email)
          user = User.new
          user.email = user_email
          user.password = SecureRandom.base58(50)
          family = Family.new
          user.family = family
          user.role = :admin
          user.save
        end
        create_session_for(user)
      end
    end

    def find_session_by_cookie
      cookie_value = cookies.signed[:session_token]

      if cookie_value.present?
        Session.find_by(id: cookie_value)
      else
        nil
      end
    end

    def create_session_for(user)
      session = user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }
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
