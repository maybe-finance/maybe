module Invitable
  extend ActiveSupport::Concern

  included do
    helper_method :invite_code_required?
  end

  private
    def invite_code_required?
      return false if @invitation.present?
      self_hosted? ? Setting.require_invite_for_signup : ENV["REQUIRE_INVITE_CODE"] == "true"
    end

    def self_hosted?
      Rails.application.config.app_mode.self_hosted?
    end
end
