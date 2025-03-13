class ApplicationController < ActionController::Base
  include Onboardable, Localize, AutoSync, Authentication, Invitable, SelfHostable, StoreLocation, Impersonatable, Breadcrumbable
  include Pagy::Backend

  helper_method :require_upgrade?, :subscription_pending?

  before_action :detect_os
  before_action :set_chat_for_sidebar

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

    def set_chat_for_sidebar
      return unless Current.user
      return unless params[:chat_id].present?

      @chat = Current.user.chats.find_by(id: params[:chat_id])
      if @chat
        @messages = @chat.messages.conversation.ordered
        @message = Message.new
      end
    end
end
