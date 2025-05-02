module Onboardable
  extend ActiveSupport::Concern

  included do
    before_action :require_onboarding_and_upgrade
    helper_method :subscription_pending?
  end

  private
    # A subscription goes into "pending" mode immediately after checkout, but before webhooks are processed.
    def subscription_pending?
      subscribed_at = Current.session.subscribed_at
      subscribed_at.present? && subscribed_at <= Time.current && subscribed_at > 1.hour.ago
    end

    # First, we require onboarding, then once that's complete, we require an upgrade for non-subscribed users.
    def require_onboarding_and_upgrade
      return unless Current.user
      return unless redirectable_path?(request.path)

      if !Current.user.onboarded?
        redirect_to onboarding_path
      elsif !Current.family.subscribed? && !Current.family.trialing? && !self_hosted?
        redirect_to upgrade_subscription_path
      end
    end

    def redirectable_path?(path)
      return false if path.starts_with?("/settings")
      return false if path.starts_with?("/subscription")
      return false if path.starts_with?("/onboarding")
      return false if path.starts_with?("/users")

      [
        new_registration_path,
        new_session_path,
        new_password_reset_path,
        new_email_confirmation_path
      ].exclude?(path)
    end
end
