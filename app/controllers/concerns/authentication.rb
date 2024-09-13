module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  class_methods do
    def skip_authentication(**options)
      skip_before_action :authenticate_user!, **options
    end
  end

  private

    def authenticate_user!
      if user = User.find_by(id: session[:user_id])
        Current.user = user
      else
        if self_hosted_first_login?
          redirect_to new_registration_url
        else
          redirect_to new_session_url
        end
      end
    end

    def login(user)
      Current.user = user
      reset_session
      session[:user_id] = user.id
      set_last_login_at
    end

    def logout
      Current.user = nil
      reset_session
    end

    def set_last_login_at
      Current.user.update(last_login_at: DateTime.now)
    end

    def self_hosted_first_login?
      Rails.application.config.app_mode.self_hosted? && User.count.zero?
    end
end
