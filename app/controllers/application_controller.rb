class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend

  before_action :sync_accounts

  default_form_builder ApplicationFormBuilder

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def hosted_app?
    ENV["HOSTED"] == "true"
  end
  helper_method :hosted_app?

  def sync_accounts
    return if Current.user.blank?

    if Current.user.last_login_at.nil? || Current.user.last_login_at.before?(Date.current.beginning_of_day)
      Current.family.sync_accounts
    end
  end
end
