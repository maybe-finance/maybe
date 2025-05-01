class ApplicationController < ActionController::Base
  include Onboardable, Localize, AutoSync, Authentication, Invitable, SelfHostable, StoreLocation, Impersonatable, Breadcrumbable, FeatureGuardable, Notifiable
  include Pagy::Backend

  helper_method :require_upgrade?, :subscription_pending?

  before_action :detect_os
  before_action :set_default_chat
  before_action :set_active_storage_url_options

  private
    def require_upgrade?
      return false if self_hosted?
      return false unless Current.session
      return false if Current.family.subscribed?
      return false if subscription_pending? || request.path == settings_billing_path
      return false if Current.family.active_accounts_count <= 3

      true
    end

    def subscription_pending?
      subscribed_at = Current.session.subscribed_at
      subscribed_at.present? && subscribed_at <= Time.current && subscribed_at > 1.hour.ago
    end

    def detect_os
      user_agent = request.user_agent
      @os = case user_agent
      when /Windows/i then "windows"
      when /Macintosh/i then "mac"
      when /Linux/i then "linux"
      when /Android/i then "android"
      when /iPhone|iPad/i then "ios"
      else ""
      end
    end

    # By default, we show the user the last chat they interacted with
    def set_default_chat
      @last_viewed_chat = Current.user&.last_viewed_chat
      @chat = @last_viewed_chat
    end

    def set_active_storage_url_options
      ActiveStorage::Current.url_options = {
        protocol: request.protocol.delete("://"),
        host: request.host,
        port: request.optional_port
      }
    end
end
