module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_request_details
    before_action :authenticate_user!
    helper_method :impersonating?
  end

  class_methods do
    def skip_authentication(**options)
      skip_before_action :authenticate_user!, **options
    end
  end

  private
    def authenticate_user!
      resume_session || request_authentication
    end

    def resume_session
      Current.impersonated_user = find_impersonated_user
      Current.session = find_session_by_cookie
    end

    def request_authentication
      if session_record = find_session_by_cookie
        Current.session = session_record
      else
        if self_hosted_first_login?
          redirect_to new_registration_url
        else
          redirect_to new_session_url
        end
      end
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_token])
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

    def impersonating?
      Current.impersonated_user.present?
    end

    def impersonate(user)
      Current.impersonated_user = user
      session[:impersonated_user_id] = user.id
    end

    def find_impersonated_user
      if (id = session[:impersonated_user_id])
        User.find_by(id: id)
      end
    end

    def stop_impersonating
      Current.impersonated_user = nil
      session.delete(:impersonated_user_id)
    end
end
