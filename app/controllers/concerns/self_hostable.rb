module SelfHostable
  extend ActiveSupport::Concern

  included do
    helper_method :self_hosted?, :self_hosted_first_login?

    prepend_before_action :verify_self_host_config
  end

  private
    def self_hosted?
      Rails.configuration.app_mode.self_hosted?
    end

    def self_hosted_first_login?
      self_hosted? && User.count.zero?
    end

    def verify_self_host_config
      return unless self_hosted?

      # Special handling for Redis configuration error page
      if controller_name == "pages" && action_name == "redis_configuration_error"
        # If Redis is now working, redirect to home
        if redis_connected?
          redirect_to root_path, notice: "Redis is now configured properly! You can now setup your Maybe application."
        end

        return
      end

      unless redis_connected?
        redirect_to redis_configuration_error_path
      end
    end

    def redis_connected?
      Redis.new.ping
      true
    rescue Redis::CannotConnectError
      false
    end
end
